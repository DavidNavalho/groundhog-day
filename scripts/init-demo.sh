#!/usr/bin/env bash
set -eux

# 1) Wait for Kafka to be ready
cub kafka-ready -b kafka:9092 1 20

# 2) Create topics (idempotent)
kafka-topics --bootstrap-server kafka:9092 \
  --create --topic transactions --partitions 1 --replication-factor 1 || true
kafka-topics --bootstrap-server kafka:9092 \
  --create --topic suspicious --partitions 1 --replication-factor 1 || true

# 3) Wait for Elasticsearch
# 3) Wait for Elasticsearch to be yellow or green
# Wait for Elasticsearch to be yellow or green (no jq required)
echo "⏳ Waiting for Elasticsearch (yellow or green)…"
while true; do
  health_json=$(curl -s http://elasticsearch:9200/_cluster/health)
  # Extract the status field value via grep/sed
  status=$(echo "$health_json" | grep -oP '"status"\s*:\s*"\K[^"]+')
  if [[ "$status" == "yellow" || "$status" == "green" ]]; then
    echo "✅ Elasticsearch is $status"
    break
  fi
  echo "⏳ Current ES status: $status; retrying…"
  sleep 2
done

# 4) Push index template so timestamp is a date
curl -X PUT http://elasticsearch:9200/_index_template/fraud_demo_template \
  -H 'Content-Type: application/json' -d @/scripts/fraud_demo_template.json

# 5) Submit Flink SQL job
#    (Note: uses the embedded SQL client in non-interactive mode)
# until docker exec flink-jobmanager \
#       /opt/flink/bin/sql-client.sh embedded -f /opt/flink/sql/pipeline.sql ; do
#   echo "Retry Flink SQL submission…"; sleep 5
# done

# 6) Wait for Kibana
until curl -s http://kibana:5601/api/status | grep '"overall":' ; do
  echo "Waiting for Kibana…"; sleep 2
done

# 7) Import Kibana saved objects (visualizations + dashboard)
#    Use the Kibana import API; the JSON files should live in /scripts
curl -X POST 'http://kibana:5601/api/saved_objects/_import?overwrite=true' \
     -H 'kbn-xsrf: true' \
     --form file=@/scripts/transactions_chart.ndjson

curl -X POST 'http://kibana:5601/api/saved_objects/_import?overwrite=true' \
     -H 'kbn-xsrf: true' \
     --form file=@/scripts/suspicious_chart.ndjson

curl -X POST 'http://kibana:5601/api/saved_objects/_import?overwrite=true' \
     -H 'kbn-xsrf: true' \
     --form file=@/scripts/fraud_demo_dashboard.ndjson

echo "🎉 Demo initialization complete."