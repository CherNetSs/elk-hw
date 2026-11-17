#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi
stage="${1:-logstash}"
case "$stage" in logstash|filebeat) ;; *) echo "Usage: $0 logstash|filebeat" >&2; exit 1 ;; esac
base="http://${SERVER_IP:-192.168.1.13}:8088"
for n in $(seq 1 12); do
  curl -fsS -o /dev/null -A "elk-homework-$stage" "$base/lab/$stage/request-$n"
done
curl -sS -o /dev/null -A "elk-homework-$stage" "$base/missing?stage=$stage"
curl -fsS -o /dev/null -X POST -A "elk-homework-$stage" "$base/lab/$stage/submit"
echo "Generated 14 requests for $stage"
