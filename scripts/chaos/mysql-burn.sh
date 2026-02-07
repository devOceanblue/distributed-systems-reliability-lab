#!/usr/bin/env bash
set -euo pipefail

host="${MYSQL_HOST:-127.0.0.1}"
port="${MYSQL_PORT:-13306}"
user="${MYSQL_USER:-root}"
password="${MYSQL_PASSWORD:-root}"
loops="${1:-100}"

for _ in $(seq 1 "$loops"); do
  mysql -h "$host" -P "$port" -u "$user" -p"$password" -e 'SELECT SLEEP(0.01);' >/dev/null
done

echo "[OK] mysql burn loops=$loops"
