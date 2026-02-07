#!/usr/bin/env bash
set -euo pipefail

state_dir="${LAB_STATE_DIR:-.lab/state}"
mkdir -p "$state_dir"
out="$state_dir/aws-kafka-smoke.log"

[[ -n "${KAFKA_BOOTSTRAP_SERVERS:-}" ]] || { echo "KAFKA_BOOTSTRAP_SERVERS is required" >&2; exit 1; }
[[ "${LAB_PROFILE:-aws}" == "aws" ]] || { echo "LAB_PROFILE should be aws" >&2; exit 1; }

if [[ "$KAFKA_BOOTSTRAP_SERVERS" == *"timeout"* ]]; then
  echo "network_error: bootstrap unreachable" >&2
  exit 70
fi

mechanism="${KAFKA_SASL_MECHANISM:-AWS_MSK_IAM}"
if [[ "$mechanism" != "AWS_MSK_IAM" && "$mechanism" != "OAUTHBEARER" ]]; then
  echo "auth_error: unsupported SASL mechanism ($mechanism)" >&2
  exit 71
fi

if [[ "${AWS_IAM_POLICY_MODE:-allow}" == "deny_write" ]]; then
  echo "authz_error: topic write denied by IAM policy" >&2
  exit 72
fi

printf 'produce_ok\t%s\t%s\n' "$(date +%s)" "$KAFKA_BOOTSTRAP_SERVERS" >> "$out"
echo "[OK] aws kafka produce smoke marker written"
