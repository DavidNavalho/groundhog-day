#!/usr/bin/env bash
set -euo pipefail

JOB_NAME="fraud-demo-job"

echo "⏳ Waiting for Flink REST API…"
until curl -fsS http://jobmanager:8081/jobs >/dev/null; do
  echo "  – Flink REST not up yet, retrying in 5s…"
  sleep 5
done

# Check if our named job is already running
if curl -fsS http://jobmanager:8081/jobs/overview \
     | grep -q "\"name\":\"${JOB_NAME}\""; then
  echo "✅ Job '${JOB_NAME}' is already submitted. Skipping."
  exit 0
fi

echo "🚀 Submitting Flink SQL job…"
until /opt/flink/bin/sql-client.sh embedded \
      -D pipeline.name="${JOB_NAME}" \
      -f /opt/flink/sql/pipeline.sql; do
  echo "❌ Submission failed, retrying in 10s…"
  sleep 10
done

echo "✅ Flink SQL submission succeeded."