#!/usr/bin/env bash
set -euo pipefail
stage="${1:-filebeat}"
case "$stage" in logstash|filebeat) ;; *) echo "Usage: $0 logstash|filebeat" >&2; exit 1 ;; esac
curl -fsS -X POST "http://localhost:9200/nginx-$stage-*/_refresh" >/dev/null
curl -fsS "http://localhost:9200/nginx-$stage-*/_search?size=100" |
  python3 -c '
import json, sys
stage = sys.argv[1]
result = json.load(sys.stdin)
assert result["_shards"]["failed"] == 0, result
docs = [hit["_source"] for hit in result["hits"]["hits"]]
assert len(docs) >= 14, f"Only {len(docs)} documents received"
assert all(d["labels"]["shipper"] == stage for d in docs)
assert all(d["event"]["dataset"] == "nginx.access" for d in docs)
assert all(d["service"]["name"] == "nginx" for d in docs)
assert all("@timestamp" in d and "time" not in d for d in docs)
assert all("error" not in d for d in docs), docs
assert all(not any(t in d.get("tags", []) for t in ["_jsonparsefailure", "_dateparsefailure"]) for d in docs)
assert all(isinstance(d["http"]["response"]["status_code"], int) for d in docs)
assert all(f"/lab/{stage}/" in d["url"]["original"] or f"stage={stage}" in d["url"]["original"] for d in docs)
assert any(d["http"]["response"]["status_code"] == 404 for d in docs)
assert any(d["http"]["request"]["method"] == "POST" for d in docs)
print(f"PASS: {len(docs)} Nginx events via {stage}; parsed timestamps, fields, GET/POST and 200/404 verified")
' "$stage"
