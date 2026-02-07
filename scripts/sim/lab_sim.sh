#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${LAB_STATE_DIR:-.lab/state}"
mkdir -p "$STATE_DIR"

accounts_file="$STATE_DIR/account.tsv"
ledger_file="$STATE_DIR/ledger.tsv"
outbox_file="$STATE_DIR/outbox.tsv"
outbox_seq_file="$STATE_DIR/outbox.seq"
main_topic_file="$STATE_DIR/topic-main.tsv"
retry_5s_file="$STATE_DIR/topic-retry-5s.tsv"
retry_1m_file="$STATE_DIR/topic-retry-1m.tsv"
dlq_file="$STATE_DIR/topic-dlq.tsv"
tx_topic_file="$STATE_DIR/topic-tx.tsv"
tx_open_file="$STATE_DIR/topic-tx-open.tsv"
projection_file="$STATE_DIR/projection.tsv"
processed_file="$STATE_DIR/processed.tsv"
replay_audit_file="$STATE_DIR/replay_audit.tsv"
cache_file="$STATE_DIR/cache.tsv"
offset_file="$STATE_DIR/consumer.offset"
metrics_file="$STATE_DIR/metrics.env"

init_state() {
  mkdir -p "$STATE_DIR"
  : > "$accounts_file"
  : > "$ledger_file"
  : > "$outbox_file"
  : > "$main_topic_file"
  : > "$retry_5s_file"
  : > "$retry_1m_file"
  : > "$dlq_file"
  : > "$tx_topic_file"
  : > "$tx_open_file"
  : > "$projection_file"
  : > "$processed_file"
  : > "$replay_audit_file"
  : > "$cache_file"
  echo "1" > "$outbox_seq_file"
  echo "0" > "$offset_file"
  cat > "$metrics_file" <<'METRICS'
CACHE_HIT=0
CACHE_MISS=0
DB_READ=0
METRICS
}

ensure_account() {
  local account_id="$1"
  if ! grep -q "^${account_id}[[:space:]]" "$accounts_file" 2>/dev/null; then
    printf '%s\t%s\n' "$account_id" "0" >> "$accounts_file"
    printf '%s\t%s\t%s\n' "$account_id" "0" "0" >> "$projection_file"
  fi
}

get_account_balance() {
  local account_id="$1"
  awk -F '\t' -v account="$account_id" '$1 == account {print $2}' "$accounts_file" | tail -n 1
}

set_account_balance() {
  local account_id="$1"
  local new_balance="$2"
  awk -F '\t' -v account="$account_id" -v next_balance="$new_balance" 'BEGIN{OFS="\t"} $1 == account {$2=next_balance} {print}' "$accounts_file" > "$accounts_file.tmp"
  mv "$accounts_file.tmp" "$accounts_file"
}

append_topic() {
  local file="$1"
  local event_id="$2"
  local dedup_key="$3"
  local account_id="$4"
  local amount="$5"
  local attempt="${6:-0}"

  local offset
  offset=$(wc -l < "$file" | tr -d ' ')
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$offset" "$event_id" "$dedup_key" "$account_id" "$amount" "$attempt" >> "$file"
}

next_outbox_id() {
  local seq
  seq=$(cat "$outbox_seq_file")
  echo $((seq + 1)) > "$outbox_seq_file"
  printf '%s' "$seq"
}

insert_outbox() {
  local event_id="$1"
  local dedup_key="$2"
  local account_id="$3"
  local amount="$4"
  local id
  id=$(next_outbox_id)
  printf '%s\t%s\t%s\t%s\t%s\tNEW\t0\n' "$id" "$event_id" "$dedup_key" "$account_id" "$amount" >> "$outbox_file"
}

update_outbox_status() {
  local id="$1"
  local next_status="$2"
  awk -F '\t' -v target_id="$id" -v target_status="$next_status" 'BEGIN{OFS="\t"} $1 == target_id {$6=target_status; if (target_status != "SENT") {$7=$7+1}} {print}' "$outbox_file" > "$outbox_file.tmp"
  mv "$outbox_file.tmp" "$outbox_file"
}

deposit() {
  local account_id="$1"
  local tx_id="$2"
  local amount="$3"
  local mode="${4:-outbox}"
  local fail_after_commit="${5:-false}"

  ensure_account "$account_id"

  if grep -q "^${tx_id}[[:space:]]" "$ledger_file" 2>/dev/null; then
    echo "duplicate tx_id: $tx_id" >&2
    return 2
  fi

  local balance
  balance=$(get_account_balance "$account_id")
  local next_balance=$((balance + amount))
  set_account_balance "$account_id" "$next_balance"
  printf '%s\t%s\t%s\n' "$tx_id" "$account_id" "$amount" >> "$ledger_file"

  local event_id="evt-${tx_id}"
  if [[ "$mode" == "outbox" ]]; then
    insert_outbox "$event_id" "$tx_id" "$account_id" "$amount"
    return 0
  fi

  if [[ "$mode" == "direct" ]]; then
    if [[ "$fail_after_commit" == "true" ]]; then
      echo "failpoint: FAILPOINT_AFTER_DB_COMMIT_BEFORE_KAFKA_SEND" >&2
      return 99
    fi
    append_topic "$main_topic_file" "$event_id" "$tx_id" "$account_id" "$amount"
    return 0
  fi

  echo "unknown produce mode: $mode" >&2
  return 2
}

withdraw() {
  local account_id="$1"
  local tx_id="$2"
  local amount="$3"
  deposit "$account_id" "$tx_id" "$((-1 * amount))" "${4:-outbox}" "${5:-false}"
}

relay_once() {
  local fail_after_send_before_mark_sent="${1:-false}"
  local fail_before_send="${2:-false}"

  local row
  row=$(awk -F '\t' '$6 != "SENT" {print; exit}' "$outbox_file")
  if [[ -z "$row" ]]; then
    return 0
  fi

  IFS=$'\t' read -r id event_id dedup_key account_id amount status attempts <<< "$row"
  update_outbox_status "$id" "SENDING"

  if [[ "$fail_before_send" == "true" ]]; then
    echo "failpoint: FAILPOINT_BEFORE_KAFKA_SEND" >&2
    return 98
  fi

  append_topic "$main_topic_file" "$event_id" "$dedup_key" "$account_id" "$amount"

  if [[ "$fail_after_send_before_mark_sent" == "true" ]]; then
    echo "failpoint: FAILPOINT_AFTER_KAFKA_SEND_BEFORE_MARK_SENT" >&2
    return 97
  fi

  update_outbox_status "$id" "SENT"
}

has_processed() {
  local consumer_group="$1"
  local dedup_key="$2"
  grep -q "^${consumer_group}[[:space:]]${dedup_key}$" "$processed_file" 2>/dev/null
}

mark_processed() {
  local consumer_group="$1"
  local dedup_key="$2"
  printf '%s\t%s\n' "$consumer_group" "$dedup_key" >> "$processed_file"
}

get_projection() {
  local account_id="$1"
  awk -F '\t' -v account="$account_id" '$1 == account {print $2 "\t" $3}' "$projection_file" | tail -n 1
}

set_projection() {
  local account_id="$1"
  local balance="$2"
  local version="$3"
  awk -F '\t' -v account="$account_id" -v next_balance="$balance" -v next_version="$version" 'BEGIN{OFS="\t"} $1 == account {$2=next_balance; $3=next_version} {print}' "$projection_file" > "$projection_file.tmp"
  mv "$projection_file.tmp" "$projection_file"
}

delete_cache() {
  local account_id="$1"
  awk -F '\t' -v account="$account_id" '$1 != account {print}' "$cache_file" > "$cache_file.tmp"
  mv "$cache_file.tmp" "$cache_file"
}

append_cache() {
  local account_id="$1"
  local value="$2"
  local ttl_seconds="$3"
  local now
  now=$(date +%s)
  local expire_at=$((now + ttl_seconds))
  delete_cache "$account_id"
  printf '%s\t%s\t%s\n' "$account_id" "$value" "$expire_at" >> "$cache_file"
}

advance_offset() {
  local current
  current=$(cat "$offset_file")
  echo $((current + 1)) > "$offset_file"
}

read_metric() {
  local key="$1"
  awk -F '=' -v target="$key" '$1 == target {print $2}' "$metrics_file" | tail -n 1
}

inc_metric() {
  local key="$1"
  local current
  current=$(read_metric "$key")
  awk -F '=' -v target="$key" -v next_value="$((current + 1))" 'BEGIN{OFS="="} $1 == target {$2=next_value} {print}' "$metrics_file" > "$metrics_file.tmp"
  mv "$metrics_file.tmp" "$metrics_file"
}

consumer_once() {
  local consumer_group="${1:-consumer-service}"
  local idempotency_mode="${2:-processed_table}"
  local offset_commit_mode="${3:-after_db}"
  local fail_after_offset_commit_before_db="${4:-false}"
  local force_permanent_account="${5:-}"
  local cache_invalidation_mode="${6:-DEL}"

  local offset
  offset=$(cat "$offset_file")
  local line_number=$((offset + 1))
  local event
  event=$(sed -n "${line_number}p" "$main_topic_file")

  if [[ -z "$event" ]]; then
    return 0
  fi

  IFS=$'\t' read -r event_offset event_id dedup_key account_id amount attempt <<< "$event"
  ensure_account "$account_id"

  if [[ "$offset_commit_mode" == "before_db" ]]; then
    advance_offset
    if [[ "$fail_after_offset_commit_before_db" == "true" ]]; then
      echo "failpoint: FAILPOINT_AFTER_OFFSET_COMMIT_BEFORE_DB_COMMIT" >&2
      return 96
    fi
  fi

  if [[ -n "$force_permanent_account" && "$account_id" == "$force_permanent_account" ]]; then
    append_topic "$dlq_file" "$event_id" "$dedup_key" "$account_id" "$amount" "$attempt"
    if [[ "$offset_commit_mode" == "after_db" ]]; then
      advance_offset
    fi
    return 0
  fi

  if [[ "$idempotency_mode" == "processed_table" ]]; then
    if has_processed "$consumer_group" "$dedup_key"; then
      if [[ "$offset_commit_mode" == "after_db" ]]; then
        advance_offset
      fi
      return 0
    fi
    mark_processed "$consumer_group" "$dedup_key"
  fi

  local projection
  projection=$(get_projection "$account_id")
  local current_balance current_version
  IFS=$'\t' read -r current_balance current_version <<< "$projection"
  current_balance="${current_balance:-0}"
  current_version="${current_version:-0}"
  local next_balance=$((current_balance + amount))
  local next_version=$((current_version + 1))
  set_projection "$account_id" "$next_balance" "$next_version"

  if [[ "$cache_invalidation_mode" == "DEL" ]]; then
    delete_cache "$account_id"
  fi

  if [[ "$offset_commit_mode" == "after_db" ]]; then
    advance_offset
  fi
}

query_balance() {
  local account_id="$1"
  local ttl_seconds="${2:-30}"
  local cache_mode="${3:-DEL}"
  local now
  now=$(date +%s)

  local cached
  cached=$(awk -F '\t' -v account="$account_id" '$1 == account {print $2 "\t" $3}' "$cache_file" | tail -n 1)
  if [[ -n "$cached" ]]; then
    local value expires_at
    IFS=$'\t' read -r value expires_at <<< "$cached"
    if (( now <= expires_at )); then
      inc_metric "CACHE_HIT"
      echo "$value"
      return 0
    fi
  fi

  inc_metric "CACHE_MISS"
  inc_metric "DB_READ"
  local projection
  projection=$(get_projection "$account_id")
  local balance version
  IFS=$'\t' read -r balance version <<< "$projection"
  balance="${balance:-0}"

  if [[ "$cache_mode" != "NONE" ]]; then
    append_cache "$account_id" "$balance" "$ttl_seconds"
  fi
  echo "$balance"
}

replay_dlq() {
  local account_filter="${1:-*}"
  local dry_run="${2:-false}"

  while IFS=$'\t' read -r offset event_id dedup_key account_id amount attempt; do
    [[ -z "$offset" ]] && continue
    if [[ "$account_filter" != "*" && "$account_filter" != "$account_id" ]]; then
      continue
    fi
    if [[ -z "$dedup_key" ]]; then
      continue
    fi

    printf '%s\t%s\t%s\t%s\n' "dlq" "$dedup_key" "replayed" "$(date +%s)" >> "$replay_audit_file"
    if [[ "$dry_run" != "true" ]]; then
      append_topic "$main_topic_file" "$event_id" "$dedup_key" "$account_id" "$amount" "$attempt"
    fi
  done < "$dlq_file"
}

tx_remove_open() {
  local tx_id="$1"
  awk -F '\t' -v target="$tx_id" '$1 != target {print}' "$tx_open_file" > "$tx_open_file.tmp"
  mv "$tx_open_file.tmp" "$tx_open_file"
}

tx_reset() {
  : > "$tx_topic_file"
  : > "$tx_open_file"
}

tx_begin() {
  local tx_id="$1"
  if grep -q "^${tx_id}$" "$tx_open_file" 2>/dev/null; then
    echo "transaction already open: $tx_id" >&2
    return 2
  fi
  printf '%s\n' "$tx_id" >> "$tx_open_file"
}

tx_send() {
  local tx_id="$1"
  local dedup_key="$2"
  local account_id="$3"
  local amount="$4"

  if ! grep -q "^${tx_id}$" "$tx_open_file" 2>/dev/null; then
    echo "transaction is not open: $tx_id" >&2
    return 2
  fi

  local offset
  offset=$(wc -l < "$tx_topic_file" | tr -d ' ')
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$offset" "$tx_id" "OPEN" "$dedup_key" "$account_id" "$amount" >> "$tx_topic_file"
}

tx_close() {
  local tx_id="$1"
  local final_state="$2"

  tx_remove_open "$tx_id"
  awk -F '\t' -v target="$tx_id" -v next_state="$final_state" \
    'BEGIN{OFS="\t"} $2 == target && $3 == "OPEN" {$3=next_state} {print}' "$tx_topic_file" > "$tx_topic_file.tmp"
  mv "$tx_topic_file.tmp" "$tx_topic_file"
}

tx_commit() {
  tx_close "$1" "COMMITTED"
}

tx_abort() {
  tx_close "$1" "ABORTED"
}

tx_leo() {
  wc -l < "$tx_topic_file" | tr -d ' '
}

tx_hw() {
  # Single replica local simulation: HW ~= LEO.
  tx_leo
}

tx_lso() {
  local first_open
  first_open=$(awk -F '\t' '$3 == "OPEN" {print $1; exit}' "$tx_topic_file")
  if [[ -n "$first_open" ]]; then
    echo "$first_open"
    return 0
  fi
  tx_leo
}

tx_read_uncommitted_count() {
  wc -l < "$tx_topic_file" | tr -d ' '
}

tx_read_committed_count() {
  local lso
  lso=$(tx_lso)
  awk -F '\t' -v target_lso="$lso" '$1 < target_lso && $3 == "COMMITTED" {c++} END{print c+0}' "$tx_topic_file"
}

count_rows() {
  local target="$1"
  local offset
  case "$target" in
    accounts) wc -l < "$accounts_file" | tr -d ' ' ;;
    ledger) wc -l < "$ledger_file" | tr -d ' ' ;;
    outbox) wc -l < "$outbox_file" | tr -d ' ' ;;
    outbox_pending) awk -F '\t' '$6 != "SENT" {c++} END{print c+0}' "$outbox_file" ;;
    main_topic) wc -l < "$main_topic_file" | tr -d ' ' ;;
    main_unconsumed)
      offset=$(cat "$offset_file")
      local total
      total=$(wc -l < "$main_topic_file" | tr -d ' ')
      if (( total < offset )); then
        echo "0"
      else
        echo $((total - offset))
      fi
      ;;
    projection) wc -l < "$projection_file" | tr -d ' ' ;;
    processed) wc -l < "$processed_file" | tr -d ' ' ;;
    dlq) wc -l < "$dlq_file" | tr -d ' ' ;;
    replay_audit) wc -l < "$replay_audit_file" | tr -d ' ' ;;
    offset) cat "$offset_file" ;;
    cache_hit) read_metric "CACHE_HIT" ;;
    cache_miss) read_metric "CACHE_MISS" ;;
    db_read) read_metric "DB_READ" ;;
    *) echo "unknown table: $target" >&2; return 2 ;;
  esac
}

inspect_value() {
  local target="$1"
  local account_id="${2:-}"
  case "$target" in
    domain_balance)
      get_account_balance "$account_id"
      ;;
    projection_balance)
      awk -F '\t' -v account="$account_id" '$1 == account {print $2}' "$projection_file" | tail -n 1
      ;;
    outbox_statuses)
      awk -F '\t' '{print $1 ":" $6}' "$outbox_file"
      ;;
    *)
      echo "unknown inspect target: $target" >&2
      return 2
      ;;
  esac
}

seed_accounts() {
  local count="$1"
  local i
  for ((i = 1; i <= count; i++)); do
    ensure_account "A-${i}"
  done
}

usage() {
  cat <<'USAGE'
Usage:
  lab_sim.sh reset
  lab_sim.sh seed <count>
  lab_sim.sh deposit <account_id> <tx_id> <amount> [outbox|direct] [failpoint]
  lab_sim.sh withdraw <account_id> <tx_id> <amount> [outbox|direct] [failpoint]
  lab_sim.sh relay-once [fail_after_send_before_mark_sent] [fail_before_send]
  lab_sim.sh consume-once [consumer_group] [processed_table|none] [after_db|before_db] [fail_after_offset_before_db] [force_permanent_account] [cache_invalidation_mode]
  lab_sim.sh query <account_id> [ttl_seconds] [cache_mode]
  lab_sim.sh replay-dlq [account_filter|*] [dry_run]
  lab_sim.sh tx-reset
  lab_sim.sh tx-begin <tx_id>
  lab_sim.sh tx-send <tx_id> <dedup_key> <account_id> <amount>
  lab_sim.sh tx-commit <tx_id>
  lab_sim.sh tx-abort <tx_id>
  lab_sim.sh tx-leo
  lab_sim.sh tx-hw
  lab_sim.sh tx-lso
  lab_sim.sh tx-read-uncommitted
  lab_sim.sh tx-read-committed
  lab_sim.sh count <accounts|ledger|outbox|outbox_pending|main_topic|main_unconsumed|projection|processed|dlq|replay_audit|offset|cache_hit|cache_miss|db_read>
  lab_sim.sh inspect <domain_balance|projection_balance|outbox_statuses> [account_id]
USAGE
}

main() {
  local cmd="${1:-}"
  case "$cmd" in
    reset)
      init_state
      ;;
    seed)
      seed_accounts "$2"
      ;;
    deposit)
      deposit "$2" "$3" "$4" "${5:-outbox}" "${6:-false}"
      ;;
    withdraw)
      withdraw "$2" "$3" "$4" "${5:-outbox}" "${6:-false}"
      ;;
    relay-once)
      relay_once "${2:-false}" "${3:-false}"
      ;;
    consume-once)
      consumer_once "${2:-consumer-service}" "${3:-processed_table}" "${4:-after_db}" "${5:-false}" "${6:-}" "${7:-DEL}"
      ;;
    query)
      query_balance "$2" "${3:-30}" "${4:-DEL}"
      ;;
    replay-dlq)
      replay_dlq "${2:-*}" "${3:-false}"
      ;;
    tx-reset)
      tx_reset
      ;;
    tx-begin)
      tx_begin "$2"
      ;;
    tx-send)
      tx_send "$2" "$3" "$4" "$5"
      ;;
    tx-commit)
      tx_commit "$2"
      ;;
    tx-abort)
      tx_abort "$2"
      ;;
    tx-leo)
      tx_leo
      ;;
    tx-hw)
      tx_hw
      ;;
    tx-lso)
      tx_lso
      ;;
    tx-read-uncommitted)
      tx_read_uncommitted_count
      ;;
    tx-read-committed)
      tx_read_committed_count
      ;;
    count)
      count_rows "$2"
      ;;
    inspect)
      inspect_value "$2" "${3:-}"
      ;;
    *)
      usage
      return 2
      ;;
  esac
}

main "$@"
