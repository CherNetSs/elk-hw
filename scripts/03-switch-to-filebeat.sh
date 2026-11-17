#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Run only after confirming all task 3 requests have reached Elasticsearch.
docker compose --profile logstash stop logstash
# Archive old records without truncating them; reopen the same access.log path.
docker compose exec -T nginx sh -c 'if [ -s /var/log/nginx-lab/access.log ]; then mv /var/log/nginx-lab/access.log "/var/log/nginx-lab/access.log.logstash-$(date +%s)"; fi; nginx -s reopen'
docker compose --profile filebeat up -d filebeat
bash scripts/02-generate-traffic.sh filebeat
