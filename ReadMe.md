# Shop Application

## Business Scenario

There is an Order Service that publishes order events to Kafka.

**Event structure:**

```json
{
  "orderId": "123",
  "userId": "42",
  "amount": 99.99,
  "createdAt": "2026-01-07T10:15:00"
}
```

Another service (Order Consumer) must:

- Read messages from Kafka
- Log them
- Confirm processing (commit offset)

## Requirements

### Kafka Configuration

- **Topic:** `orders`
- **Partitions:** 3
- **Consumer Group:** `order-consumer-group`
- **Delivery Guarantee:** at-least-once
- **Message Ordering:** by `orderId`

### Technical Requirements

- Java 17
- Spring Boot
- Spring Kafka
- JSON (Jackson)
- Manual offset commit

## Architecture

```
[REST API]
    |
    v
[Kafka Producer] ---> [Kafka Topic: orders] ---> [Kafka Consumer]
```

### Component Details

| Component | Technology | Description |
|-----------|-----------|-------------|
| **Producer** | Spring Kafka | Sends order events with idempotent guarantee |
| **Kafka Topic** | Apache Kafka | 3 partitions, replication factor 1 |
| **Consumer** | @KafkaListener | Manual commit, processes messages sequentially |
| **Serialization** | Jackson (JSR310) | JSON with Java 8 time support |
| **Partition Strategy** | Hash by orderId | Ensures ordering per orderId |

## Testing & Verification

### Testing Scripts

The project includes automated scripts for message verification:

```
/Users/azeltser/IdeaProjects/shop/
├── count-messages.sh      ← Count and display all messages
├── verify-complete.sh     ← Complete delivery verification
└── TESTING-GUIDE.md       ← Detailed testing documentation
```

### Quick Start

**1. Count all messages in Kafka:**
```bash
./count-messages.sh
```

**2. Verify complete message delivery:**
```bash
./verify-complete.sh
```

**3. Check consumer statistics via API:**
```bash
curl http://localhost:8080/stats
```

### Response Example
```json
{
  "processedMessages": 10,
  "consumerGroup": "order-consumer-group",
  "topic": "orders"
}
```

For detailed testing instructions, see [TESTING-GUIDE.md](TESTING-GUIDE.md)

## Kafka Topics Management

### Topic Commands Script

Interactive CLI tool for managing Kafka topics:

```bash
chmod +x topic-commands.sh
./topic-commands.sh
```

**Features:**
- ✅ List all topics
- ✅ Create/delete topics
- ✅ Count messages per partition
- ✅ Read messages (all or last N)
- ✅ Monitor topic in real-time
- ✅ Reset consumer offsets
- ✅ View consumer group status

### Quick Commands

```bash
# List all topics
docker exec kafka /opt/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092

# Describe orders topic
docker exec kafka /opt/kafka/bin/kafka-topics.sh --describe --bootstrap-server localhost:9092 --topic orders

# Count messages
docker exec kafka /opt/kafka/bin/kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 --topic orders --time -1
```

For comprehensive Kafka topics guide, see [KAFKA-TOPICS-GUIDE.md](KAFKA-TOPICS-GUIDE.md)
