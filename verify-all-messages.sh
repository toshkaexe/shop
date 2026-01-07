#!/bin/bash

echo "========================================="
echo "📨 Kafka Message Verification"
echo "========================================="
echo ""

# Подсчет сообщений в каждой партиции
echo "1️⃣  Messages per partition:"
docker exec kafka /opt/kafka/bin/kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic orders \
  --time -1 2>/dev/null | while IFS=: read topic partition offset; do
    echo "   📦 Partition $partition: $offset message(s)"
done
echo ""

# Общее количество
TOTAL=$(docker exec kafka /opt/kafka/bin/kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic orders \
  --time -1 2>/dev/null | awk -F ":" '{sum += $3} END {print sum}')
echo "2️⃣  Total messages: $TOTAL"
echo ""

# Читаем все сообщения и сохраняем в файл
echo "3️⃣  Extracting all messages..."
TEMP_FILE="/tmp/kafka_orders_$(date +%s).json"
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --from-beginning \
  --max-messages $TOTAL \
  --timeout-ms 3000 2>/dev/null > "$TEMP_FILE"

# Подсчет строк в файле
RECEIVED=$(wc -l < "$TEMP_FILE" | tr -d ' ')
echo "   ✅ Received: $RECEIVED message(s)"
echo ""

# Показываем все orderId
echo "4️⃣  Order IDs found:"
grep -o '"orderId":"[^"]*"' "$TEMP_FILE" | cut -d'"' -f4 | sort | uniq -c | while read count id; do
    echo "   📋 $id (sent $count time(s))"
done
echo ""

# Проверка
if [ "$RECEIVED" -eq "$TOTAL" ]; then
    echo "✅ SUCCESS: All $TOTAL messages verified!"
else
    echo "⚠️  WARNING: Expected $TOTAL but received $RECEIVED"
fi
echo ""

echo "📄 Full messages saved to: $TEMP_FILE"
echo ""
echo "========================================="