#!/usr/bin/env python3
import os
import json
import time
import datetime
from confluent_kafka import Consumer, KafkaException
from elasticsearch import Elasticsearch

# Configuration from env
KAFKA_BOOTSTRAP = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092")
TOPICS          = ["transactions", "suspicious"]
ES_URL          = f"http://{os.getenv('ES_HOST','elasticsearch')}:{os.getenv('ES_PORT','9200')}"
INDEX_ALL       = os.getenv("ES_INDEX_ALL", "transactions")
INDEX_SUS       = os.getenv("ES_INDEX_SUSPICIOUS", "suspicious")

def create_consumer():
    return Consumer({
        "bootstrap.servers": KAFKA_BOOTSTRAP,
        "group.id":          "es-indexer-group",
        "auto.offset.reset": "earliest",
    })

def main():
    es = Elasticsearch(ES_URL)
    # Ensure indices exist
    for idx in [INDEX_ALL, INDEX_SUS]:
        if not es.indices.exists(index=idx):
            es.indices.create(index=idx)
            print(f"[Indexer] Created index '{idx}'")

    consumer = create_consumer()
    consumer.subscribe(TOPICS)
    print(f"[Indexer] Subscribed to topics {TOPICS}…")

    try:
        while True:
            msg = consumer.poll(1.0)
            if msg is None:
                continue
            if msg.error():
                raise KafkaException(msg.error())

            raw = msg.value().decode("utf-8")
            print(f"[Indexer][RAW] topic={msg.topic()} value={raw}")

            try:
                doc = json.loads(raw)
            except json.JSONDecodeError as e:
                print(f"[Indexer] ERROR: invalid JSON: {e}, skipping")
                continue

            # Ensure timestamp field exists
            ts = doc.get("timestamp")
            if ts:
                try:
                    ts_clean = ts.replace(" ", "T")
                    dt = datetime.datetime.fromisoformat(ts_clean)
                    if dt.tzinfo is not None:
                        dt = dt.astimezone(datetime.timezone.utc).replace(tzinfo=None)
                    doc["timestamp"] = dt.isoformat(timespec="milliseconds") + "Z"
                except Exception as e:
                    print(f"[Indexer] Warning: malformed timestamp '{ts}': {e}")
                    ts = None    # force fallback
            if not ts:
                # fallback to now in UTC
                now = datetime.datetime.utcnow()
                doc["timestamp"] = now.isoformat(timespec="milliseconds") + "Z"
                print(f"[Indexer] Injected fallback timestamp {doc['timestamp']}")

            # Choose index
            target = INDEX_ALL if msg.topic() == "transactions" else INDEX_SUS
            es.index(index=target, document=doc)
            print(f"[Indexer] Indexed into '{target}' id={doc.get('transaction_id')}")

    finally:
        consumer.close()

if __name__ == "__main__":
    while True:
        try:
            main()
        except Exception as e:
            print(f"[Indexer] Error: {e}, retrying in 5s…")
            time.sleep(5)