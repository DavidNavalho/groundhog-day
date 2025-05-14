#!/usr/bin/env bash
set -eux

# 1) Start the JobManager as usual
/opt/flink/bin/jobmanager.sh start cluster

# 2) Wait for the REST endpoint
echo "⏳ Waiting for Flink REST on localhost:8081…"
until curl -s http://localhost:8081 ; do
  sleep 2
done
echo "✅ Flink REST is up!"

# 3) Submit SQL pipeline in interactive(-i) mode
echo "🔄 Submitting SQL pipeline..."
# The '-i' flag tells sql-client.sh that it's non-interactive and should process -f
exec /opt/flink/bin/sql-client.sh embedded -i -f /opt/flink/sql/pipeline.sql &

# 4) Tail *all* logs so the container stays alive and you can see what’s happening
tail -F /opt/flink/log/*.log