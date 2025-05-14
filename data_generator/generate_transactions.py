#!/usr/bin/env python3
import os
import time
import json
import uuid
import random
import datetime
from faker import Faker
from kafka import KafkaProducer
from kafka.errors import NoBrokersAvailable

def main():
    faker = Faker()
    bootstrap = os.environ.get("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092")
    topic     = os.environ.get("TOPIC", "transactions")

    # Retry loop for KafkaProducer
    while True:
        try:
            producer = KafkaProducer(
                bootstrap_servers=bootstrap,
                value_serializer=lambda v: json.dumps(v).encode("utf-8")
            )
            print(f"[Generator] Connected to Kafka at {bootstrap}")
            break
        except NoBrokersAvailable:
            print("[Generator] Kafka not available, retrying in 5s…")
            time.sleep(5)

    print(f"[Generator] Starting data generation → topic '{topic}'")
    while True:
        # Timestamp in the last 5 minutes, in ISO-8601 with ms precision and Z
        now = datetime.datetime.utcnow()
        ts = faker.date_time_between(start_date="-5m", end_date="now", tzinfo=None)
        timestamp = ts.isoformat(timespec="milliseconds") + "Z"

        event = {
            "transaction_id":       str(uuid.uuid4()),
            "account_id":           faker.bban(),
            "timestamp":            timestamp,
            "amount":               round(random.uniform(1, 20000), 2),
            "merchant_type":        random.choice(["grocery","electronics","gas","travel","restaurants"]),
            "transaction_location": faker.city()
        }

        producer.send(topic, event)
        print(f"[Generator] Sent {event['transaction_id']} @ €{event['amount']} on {event['timestamp']}")
        time.sleep(0.5)  # ~2 messages/sec

if __name__ == "__main__":
    main()