#!/bin/bash

echo "========================================="
echo "Kafka Message Verification Tool"
echo "========================================="
echo ""

# 1. Подсчет общего количества сообщений
echo "📊 Total messages in topic 'orders':"
MESSAGE_COUNT=$(docker exec kafka /opt/kafka/bin/kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic orders \
  --time -1 2>/dev/null | awk -F ":" '{sum += $3} END {print sum}')
echo "   ✅ Total: $MESSAGE_COUNT messages"
echo ""

# 2. Показать распределение по партициям
echo "📦 Messages per partition:"
docker exec kafka /opt/kafka/bin/kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic orders \
  --time -1 2>/dev/null | while read line; do
    partition=$(echo $line | cut -d':' -f2)
    offset=$(echo $line | cut -d':' -f3)
    echo "   Partition $partition: $offset messages"
done
echo ""

# 3. Список всех orderId в топике
echo "📋 List of Order IDs:"
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --from-beginning \
  --timeout-ms 3000 \
  --property print.key=true \
  --property key.separator=" | " 2>/dev/null | \
  grep -oP '"orderId":"[^"]*"' | \
  sort | uniq -c | \
  awk '{print "   " $1 "x - " $2}'
echo ""

# 4. Consumer Group Lag (если есть consumer group)
echo "📈 Consumer Group Status:"
docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --list 2>/dev/null | while read group; do
    if [ ! -z "$group" ]; then
      echo "   Group: $group"
      docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
        --bootstrap-server localhost:9092 \
        --group "$group" \
        --describe 2>/dev/null | grep -v "^Consumer" | grep "orders" || echo "   No active consumers"
    fi
done
echo ""

echo "========================================="
echo "✅ Verification Complete!"
echo "========================================="