# Minutes-vs-Months Streaming Demo

> **Warning:** This repository is for demo purposes only.  
> It **does not** implement a production-grade suspicious-transaction detection system.

A live, end-to-end streaming pipeline showcasing how you can stand up:

- **Data generator** → Kafka  
- **Flink SQL** filter & transform → Kafka  
- **Python indexer** → Elasticsearch  
- **Kibana** dashboard + **AKHQ** topic UI  

in under a minute, illustrating “minutes vs. months” in enterprise rollout time.

---

## 🚀 Quick Start

1. **Build all images** (only required once or after changes)  
   ```bash
   docker-compose build
   ```

2. **Bring up the demo**  
   ```bash
   docker-compose up -d
   ```

3. **Submit the Flink job**  
   ```bash
   docker exec -it flink-jobmanager \
     /opt/flink/bin/sql-client.sh embedded \
     -f /opt/flink/sql/pipeline.sql
   ```

4. **View the UIs**  
   - **Kibana:**  http://localhost:5601 → Dashboard “Real-Time Fraud Demo”  
   - **AKHQ:**   http://localhost:8082 → cluster “local” → topics  

---

## 🛠️ Cleanup

To stop everything **and** wipe all data/volumes:

```bash
docker-compose down --volumes --remove-orphans
```

---

## ⚠️ Caveats

- **Init script may need a retry:**  
  Sometimes `demo-init` runs before every service is fully ready. If you see errors during startup, re-run it once more:

  ```bash
  docker-compose run --rm demo-init
  ```

- **Not production code:**  
  - No authentication/authorization on Kafka/Elasticsearch/Kibana.  
  - Simplified timestamp handling and error recovery.  
  - Intended for live-demo only, **not** real-world transaction monitoring.

---

## 📦 What’s Inside

- **`docker-compose.yml`**  
  Defines Zookeeper, Kafka, Flink (JobManager & TaskManager), Elasticsearch, Kibana, AKHQ, data-generator, ES indexer, and `demo-init` script.

- **`data_generator/`**  
  Python script that emits synthetic, recent-timestamp transactions to Kafka.

- **`flink/sql/pipeline.sql`**  
  Flink SQL pipeline: reads raw JSON → casts timestamp → filters `amount > 10000` → upserts to `suspicious` Kafka topic.

- **`data_indexer/`**  
  Python indexer: consumes both topics, normalizes timestamps, indexes into Elasticsearch.

- **`scripts/init-demo.sh`**  
  Creates Kafka topics, applies ES index-template, imports Kibana NDJSON saved-objects.

---

## 👏 Enjoy!

Feel free to fork, explore, and adapt—but remember the real value here is **seeing how fast** you can go from zero to live streaming analytics with open-source tools.
