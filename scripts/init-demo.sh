#!/usr/bin/env bash
set -euo pipefail

# How long to sleep between retries
RETRY_INTERVAL=5

# Helper: retry a command until it succeeds
# Usage: retry_until_ok "echo hello" "optional failure message"
retry_until_ok() {
  local cmd="$1" fail_msg="${2:-Command failed, retrying…}"
  until eval "$cmd"; do
    echo "❌ $fail_msg"
    sleep "$RETRY_INTERVAL"
  done
}

echo "🔄 Starting demo-init (will retry until everything is ready)…"

# 1) Wait for Kafka
echo "⏳ Waiting for Kafka broker…"
retry_until_ok \
  "cub kafka-ready -b kafka:9092 1 20" \
  "Kafka not ready yet"

# 2) Create topics (idempotent)
echo "🎯 Creating topics…"
retry_until_ok \
  "kafka-topics --bootstrap-server kafka:9092 --create --topic transactions --partitions 1 --replication-factor 1 || true" \
  "Failed to create 'transactions' topic"
retry_until_ok \
  "kafka-topics --bootstrap-server kafka:9092 --create --topic suspicious --partitions 1 --replication-factor 1 || true" \
  "Failed to create 'suspicious' topic"

# 3) Wait for Elasticsearch (yellow or green)
echo "⏳ Waiting for Elasticsearch cluster health (yellow/green)…"
retry_until_ok \
  "curl -fsS http://elasticsearch:9200/_cluster/health | grep -E '\"status\"\s*:\s*\"(yellow|green)\"'" \
  "Elasticsearch not yet healthy"

# 4) Push index template #Remove: we don't need this anymore
# echo "📐 Installing ES index template…"
# retry_until_ok \
#   "curl -fsS -X PUT http://elasticsearch:9200/_index_template/fraud_demo_template -H 'Content-Type: application/json' -d @/scripts/fraud_demo_template.json" \
#   "Failed to push ES index template"

# 5) Submit Flink SQL job
# echo "🚀 Submitting Flink SQL job…"
# retry_until_ok \
#   "docker exec flink-jobmanager /opt/flink/bin/sql-client.sh embedded -f /opt/flink/sql/pipeline.sql" \
#   "Flink SQL submission failed"

# 6) Wait for Kibana
echo "⏳ Waiting for Kibana to be ready…"
retry_until_ok \
  "curl -fsS http://kibana:5601/api/status | grep '\"overall\":'" \
  "Kibana not ready yet"

# 7) Import Kibana saved objects
for file in transactions_chart.ndjson suspicious_chart.ndjson fraud_demo_dashboard.ndjson; do
  echo "🖼️  Importing Kibana saved object: $file"
  retry_until_ok \
    "curl -fsS -X POST 'http://kibana:5601/api/saved_objects/_import?overwrite=true' -H 'kbn-xsrf: true' --form file=@/scripts/$file" \
    "Failed to import $file"
done

echo "🎉 Demo initialization complete."