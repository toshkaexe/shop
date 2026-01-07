#!/bin/bash

echo "========================================="
echo "🔍 Message Delivery Verification"
echo "========================================="
echo ""

# Количество в топике
echo "1️⃣  Counting messages in Kafka topic..."
TOPIC_COUNT=$(docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --from-beginning \
  --timeout-ms 3000 2>/dev/null | wc -l | tr -d ' ')
echo "   📦 Messages in topic 'orders': $TOPIC_COUNT"
echo ""

# Количество обработанных Consumer
echo "2️⃣  Checking consumer statistics..."
STATS=$(curl -s http://localhost:8080/stats 2>/dev/null)
if [ $? -eq 0 ]; then
    PROCESSED=$(echo "$STATS" | grep -o '"processedMessages":[0-9]*' | cut -d':' -f2)
    echo "   ✅ Processed by consumer: $PROCESSED"
else
    echo "   ⚠️  Cannot reach application on port 8080"
    PROCESSED="N/A"
fi
echo ""

# LAG проверка
echo "3️⃣  Checking consumer group lag..."
LAG_OUTPUT=$(docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group order-consumer-group \
  --describe 2>/dev/null | grep "orders")

if [ ! -z "$LAG_OUTPUT" ]; then
    TOTAL_LAG=$(echo "$LAG_OUTPUT" | awk '{sum += $6} END {print sum}')
    echo "   📊 Current LAG: ${TOTAL_LAG:-0}"

    echo ""
    echo "   Partition details:"
    echo "$LAG_OUTPUT" | while read line; do
        partition=$(echo $line | awk '{print $2}')
        current=$(echo $line | awk '{print $3}')
        lag=$(echo $line | awk '{print $6}')
        echo "      • Partition $partition: offset=$current, lag=$lag"
    done
else
    echo "   ℹ️  No consumer group activity yet"
    TOTAL_LAG="N/A"
fi

echo ""
echo "========================================="
echo "📊 Summary"
echo "========================================="
echo "  Topic messages:     $TOPIC_COUNT"
echo "  Processed:          $PROCESSED"
echo "  Lag:                ${TOTAL_LAG:-0}"
echo ""

# Финальная проверка
if [ "$PROCESSED" != "N/A" ] && [ "$TOPIC_COUNT" -eq "$PROCESSED" ] 2>/dev/null; then
    echo "✅ ✅ ✅ SUCCESS! All messages delivered and processed! ✅ ✅ ✅"
elif [ "$TOTAL_LAG" = "0" ] 2>/dev/null; then
    echo "✅ All messages processed (LAG = 0)"
elif [ "$TOTAL_LAG" != "N/A" ] && [ "$TOTAL_LAG" -gt 0 ] 2>/dev/null; then
    echo "⚠️  WARNING: $TOTAL_LAG messages pending processing"
else
    echo "ℹ️  Consumer not active or still processing"
fi

echo ""
echo "========================================="