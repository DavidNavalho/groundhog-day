-- Source remains the same
CREATE TABLE transactions_raw (
  transaction_id       STRING,
  account_id           STRING,
  ts_string            STRING,
  amount               DOUBLE,
  merchant_type        STRING,
  transaction_location STRING
) WITH (
  'connector'                    = 'kafka',
  'topic'                        = 'transactions',
  'properties.bootstrap.servers' = 'kafka:9092',
  'properties.group.id'          = 'flink-sql',
  'format'                       = 'json',
  'scan.startup.mode'            = 'earliest-offset'
);

-- Sink back into Kafka, with a primary key on transaction_id
CREATE TABLE suspicious_kafka (
  transaction_id       STRING,
  account_id           STRING,
  `timestamp`          TIMESTAMP(3),
  amount               DOUBLE,
  merchant_type        STRING,
  transaction_location STRING,
  PRIMARY KEY (transaction_id) NOT ENFORCED
) WITH (
  'connector'                        = 'upsert-kafka',
  'topic'                            = 'suspicious',
  'properties.bootstrap.servers'     = 'kafka:9092',
  'key.format'                       = 'json',
  'value.format'                     = 'json',

  -- **Here’s the fix**: nest the timestamp-format under value.json
  'value.json.timestamp-format.standard' = 'ISO-8601'
);

-- Filter logic
-- After defining transactions_raw and suspicious_kafka as before...

INSERT INTO suspicious_kafka
SELECT
  transaction_id,
  account_id,
  -- Cast ISO-8601 string directly to TIMESTAMP(3)
  CAST(ts_string AS TIMESTAMP(3)) AS `timestamp`,
  amount,
  merchant_type,
  transaction_location
FROM transactions_raw
WHERE amount > 10000;