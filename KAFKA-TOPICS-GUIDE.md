# 📚 Kafka Topics Guide

## Что такое Topic?

**Topic** - это категория или лента, в которую публикуются сообщения в Kafka. Это логический канал для передачи данных между Producer и Consumer.

---

## 🔧 Создание Topic

### Вариант 1: Через Docker

```bash
docker exec kafka /opt/kafka/bin/kafka-topics.sh --create \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --partitions 3 \
  --replication-factor 1
```

### Вариант 2: С дополнительными настройками

```bash
docker exec kafka /opt/kafka/bin/kafka-topics.sh --create \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --partitions 3 \
  --replication-factor 1 \
  --config retention.ms=604800000 \
  --config segment.bytes=1073741824 \
  --config compression.type=lz4
```

**Параметры:**
- `--partitions 3` - количество партиций (параллелизм)
- `--replication-factor 1` - количество реплик (надежность)
- `--config retention.ms` - время хранения сообщений (7 дней)
- `--config compression.type` - тип сжатия

---

## 📋 Список всех Topics

```bash
docker exec kafka /opt/kafka/bin/kafka-topics.sh --list \
  --bootstrap-server localhost:9092
```

**Пример вывода:**
```
orders
__consumer_offsets
__transaction_state
```

---

## 🔍 Детальная информация о Topic

```bash
docker exec kafka /opt/kafka/bin/kafka-topics.sh --describe \
  --bootstrap-server localhost:9092 \
  --topic orders
```

**Пример вывода:**
```
Topic: orders   TopicId: LVlzPJiWSe2vE9juZsJ9sQ   PartitionCount: 3   ReplicationFactor: 1
    Topic: orders   Partition: 0    Leader: 1   Replicas: 1   Isr: 1
    Topic: orders   Partition: 1    Leader: 1   Replicas: 1   Isr: 1
    Topic: orders   Partition: 2    Leader: 1   Replicas: 1   Isr: 1
```

**Расшифровка:**
- **Leader** - брокер, отвечающий за чтение/запись
- **Replicas** - список брокеров с копиями данных
- **Isr (In-Sync Replicas)** - реплики, синхронизированные с Leader

---

## 📊 Статистика Topic

### Количество сообщений в каждой партиции

```bash
docker exec kafka /opt/kafka/bin/kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic orders \
  --time -1
```

**Пример вывода:**
```
orders:0:5    ← Partition 0 содержит 5 сообщений (offset 0-4)
orders:1:3    ← Partition 1 содержит 3 сообщения (offset 0-2)
orders:2:8    ← Partition 2 содержит 8 сообщений (offset 0-7)
```

### Общее количество сообщений

```bash
docker exec kafka /opt/kafka/bin/kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic orders \
  --time -1 | awk -F':' '{sum += $3} END {print "Total messages:", sum}'
```

---

## ✏️ Изменение конфигурации Topic

### Увеличить количество партиций

```bash
docker exec kafka /opt/kafka/bin/kafka-topics.sh --alter \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --partitions 5
```

⚠️ **Внимание:** Нельзя уменьшить количество партиций!

### Изменить retention period

```bash
docker exec kafka /opt/kafka/bin/kafka-configs.sh --alter \
  --bootstrap-server localhost:9092 \
  --entity-type topics \
  --entity-name orders \
  --add-config retention.ms=86400000
```

### Просмотр конфигурации Topic

```bash
docker exec kafka /opt/kafka/bin/kafka-configs.sh --describe \
  --bootstrap-server localhost:9092 \
  --entity-type topics \
  --entity-name orders
```

---

## 🗑️ Удаление Topic

### Удалить Topic полностью

```bash
docker exec kafka /opt/kafka/bin/kafka-topics.sh --delete \
  --bootstrap-server localhost:9092 \
  --topic orders
```

### Очистить все сообщения (но сохранить Topic)

```bash
# Способ 1: Установить retention в 1 секунду, потом вернуть обратно
docker exec kafka /opt/kafka/bin/kafka-configs.sh --alter \
  --bootstrap-server localhost:9092 \
  --entity-type topics \
  --entity-name orders \
  --add-config retention.ms=1000

sleep 5

docker exec kafka /opt/kafka/bin/kafka-configs.sh --alter \
  --bootstrap-server localhost:9092 \
  --entity-type topics \
  --entity-name orders \
  --delete-config retention.ms
```

---

## 📖 Чтение сообщений из Topic

### Читать с начала

```bash
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --from-beginning
```

### Читать только новые сообщения

```bash
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders
```

### Читать с конкретного offset

```bash
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --partition 0 \
  --offset 5
```

### Читать последние N сообщений

```bash
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --from-beginning \
  --max-messages 10
```

### Читать с ключом и таймстампом

```bash
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --from-beginning \
  --property print.key=true \
  --property print.timestamp=true \
  --property key.separator=" | "
```

**Пример вывода:**
```
CreateTime:1767780900000 | 123 | {"orderId":"123","userId":"42","amount":99.99}
CreateTime:1767792900000 | ORD-003 | {"orderId":"ORD-003","userId":"USER-123","amount":249.50}
```

---

## ✍️ Отправка сообщений в Topic

### Через console producer

```bash
docker exec -it kafka /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders
```

Затем вводите сообщения построчно:
```
{"orderId":"TEST-001","userId":"USER-100","amount":99.99}
{"orderId":"TEST-002","userId":"USER-101","amount":149.50}
```

### С ключом

```bash
docker exec -it kafka /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --property "parse.key=true" \
  --property "key.separator=:"
```

Формат: `key:value`
```
123:{"orderId":"123","userId":"42","amount":99.99}
456:{"orderId":"456","userId":"99","amount":199.99}
```

---

## 🔄 Примеры для разных сценариев

### Сценарий 1: Monitoring (мониторинг топика)

```bash
# Создать скрипт monitor-topic.sh
cat > monitor-topic.sh << 'EOF'
#!/bin/bash
while true; do
  clear
  echo "=== Kafka Topic: orders - Monitor ==="
  echo ""

  # Количество сообщений
  docker exec kafka /opt/kafka/bin/kafka-run-class.sh kafka.tools.GetOffsetShell \
    --broker-list localhost:9092 \
    --topic orders \
    --time -1

  echo ""
  echo "Refreshing in 5 seconds... (Ctrl+C to exit)"
  sleep 5
done
EOF

chmod +x monitor-topic.sh
./monitor-topic.sh
```

### Сценарий 2: Backup (сохранить все сообщения)

```bash
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --from-beginning \
  --timeout-ms 5000 > orders_backup_$(date +%Y%m%d_%H%M%S).json
```

### Сценарий 3: Replay (переотправить сообщения)

```bash
# 1. Сохранить сообщения
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --from-beginning > messages.txt

# 2. Создать новый топик
docker exec kafka /opt/kafka/bin/kafka-topics.sh --create \
  --bootstrap-server localhost:9092 \
  --topic orders-replay \
  --partitions 3 \
  --replication-factor 1

# 3. Отправить в новый топик
cat messages.txt | docker exec -i kafka /opt/kafka/bin/kafka-console-producer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders-replay
```

---

## 🎯 Использование в проекте

### application.properties

```properties
# Topic configuration
spring.kafka.topic.orders=orders
spring.kafka.topic.dead-letter=orders-dlq
spring.kafka.topic.retry=orders-retry

# Producer topic settings
spring.kafka.producer.properties.max.in.flight.requests.per.connection=5

# Consumer topic settings
spring.kafka.consumer.max-poll-records=500
```

### Java конфигурация (пример создания Topic программно)

```java
@Configuration
public class KafkaTopicConfig {

    @Bean
    public NewTopic ordersTopic() {
        return TopicBuilder.name("orders")
            .partitions(3)
            .replicas(1)
            .config(TopicConfig.RETENTION_MS_CONFIG, "604800000") // 7 days
            .config(TopicConfig.COMPRESSION_TYPE_CONFIG, "lz4")
            .build();
    }

    @Bean
    public NewTopic ordersRetryTopic() {
        return TopicBuilder.name("orders-retry")
            .partitions(3)
            .replicas(1)
            .build();
    }

    @Bean
    public NewTopic ordersDeadLetterTopic() {
        return TopicBuilder.name("orders-dlq")
            .partitions(1)
            .replicas(1)
            .config(TopicConfig.RETENTION_MS_CONFIG, "-1") // infinite
            .build();
    }
}
```

---

## 📐 Best Practices

### 1. Naming Convention

```
✅ Good:
- orders
- user-events
- payment-transactions
- notification-requests

❌ Bad:
- topic1
- test
- tmp
- data
```

### 2. Количество партиций

**Правило:** `partitions = expected throughput / consumer throughput`

Примеры:
- **Low traffic** (< 100 msg/sec): 1-3 партиции
- **Medium traffic** (100-1000 msg/sec): 3-10 партиций
- **High traffic** (> 1000 msg/sec): 10+ партиций

### 3. Replication Factor

- **Dev/Test:** 1
- **Production:** 3 (минимум 2)

### 4. Retention Period

```bash
# По времени
--config retention.ms=604800000  # 7 days

# По размеру
--config retention.bytes=1073741824  # 1 GB

# Оба условия (что наступит раньше)
--config retention.ms=604800000 \
--config retention.bytes=1073741824
```

---

## 🛠️ Troubleshooting

### Topic не создается

```bash
# Проверить лог Kafka
docker logs kafka --tail 100

# Проверить квоты
docker exec kafka /opt/kafka/bin/kafka-configs.sh --describe \
  --bootstrap-server localhost:9092 \
  --entity-type brokers
```

### Сообщения не читаются

```bash
# Проверить offset
docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group order-consumer-group \
  --describe

# Сбросить offset
docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group order-consumer-group \
  --reset-offsets \
  --to-earliest \
  --topic orders \
  --execute
```

### Topic переполнен

```bash
# Уменьшить retention
docker exec kafka /opt/kafka/bin/kafka-configs.sh --alter \
  --bootstrap-server localhost:9092 \
  --entity-type topics \
  --entity-name orders \
  --add-config retention.ms=3600000  # 1 hour

# Включить compression
docker exec kafka /opt/kafka/bin/kafka-configs.sh --alter \
  --bootstrap-server localhost:9092 \
  --entity-type topics \
  --entity-name orders \
  --add-config compression.type=lz4
```

---

## 📚 Полезные ссылки

- [Kafka Topics Documentation](https://kafka.apache.org/documentation/#topicconfigs)
- [Topic Configuration Best Practices](https://kafka.apache.org/documentation/#design_loadbalancing)
- [Partition Strategy Guide](https://www.confluent.io/blog/how-choose-number-topics-partitions-kafka-cluster/)

---

**💡 Совет:** Сохраните часто используемые команды в shell aliases для быстрого доступа!