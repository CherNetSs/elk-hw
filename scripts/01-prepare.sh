#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -f .env ]]; then
  set -a
  source .env
  set +a
fi
# One replica cannot be allocated on a single-node teaching cluster.
curl -fsS -X PUT http://localhost:9200/_index_template/nginx-homework \
  -H 'Content-Type: application/json' \
  --data-binary @elasticsearch/nginx-template.json
printf '\n'
curl -fsS -X POST "http://${SERVER_IP:-192.168.1.13}:5601/api/data_views/data_view" \
  -H 'kbn-xsrf: homework' -H 'Content-Type: application/json' \
  -d '{"data_view":{"id":"nginx-homework","title":"nginx-*","name":"Nginx access logs","timeFieldName":"@timestamp"},"override":true}'
printf '\n'
