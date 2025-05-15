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

### Prepare Flink connectors (run once only)

Before you build your Flink Docker images, download the two required SQL connector JARs:

```bash
# from your project root
mkdir -p flink/plugins

# Kafka SQL connector (version 3.1.0-1.18)
curl -L -o flink/plugins/flink-sql-connector-kafka-3.1.0-1.18.jar https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-kafka/3.1.0-1.18/flink-sql-connector-kafka-3.1.0-1.18.jar

# Elasticsearch7 SQL connector (version 3.1.0-1.18)
curl -L -o flink/plugins/flink-sql-connector-elasticsearch7-3.1.0-1.18.jar https://repo1.maven.org/maven2/org/apache/flink/flink-sql-connector-elasticsearch7/3.1.0-1.18/flink-sql-connector-elasticsearch7-3.1.0-1.18.jar
```

### Running the demo

 ```bash
   docker-compose up -d
   ```
  **View the UIs**  
   - **AKHQ:**   http://localhost:8082 → cluster “local” → topics  
   - **Flink Dashboard:** http://localhost:8081
   - **Kibana:**  http://localhost:5601 → Dashboard “Real-Time Fraud Demo” 
   - **Kibana Dashboards:** [kibana demo dashboard](http://localhost:5601/app/dashboards#/view/d723d171-c76d-4ad8-9b25-1c419bf8432f?_g=(filters:!(),refreshInterval:(pause:!f,value:10000),time:(from:now-5m,to:now)))




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

## Some additional information

1. [Optional] **Build all images** (only required after changes, otherwise it should build automatically on first run)  
   ```bash
   docker-compose build
   ```

2. [Optional] **Submit a Flink job from terminal** (the docker-compose already submits the job)
   ```bash
   docker exec -it flink-jobmanager /opt/flink/bin/sql-client.sh embedded -f /opt/flink/sql/pipeline.sql
   ```
---

## 👏 Enjoy!

Feel free to fork, explore, and adapt—but remember the real value here is **seeing how fast** you can go from zero to live streaming analytics with open-source tools.
