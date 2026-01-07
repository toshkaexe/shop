#!/bin/bash

echo "========================================="
echo "📊 Kafka Message Counter"
echo "========================================="
echo ""

# Читаем все сообщения и считаем
echo "Reading all messages from 'orders' topic..."
echo ""

TEMP_FILE="/tmp/kafka_messages_$(date +%s).txt"

# Читаем сообщения с большим timeout
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --from-beginning \
  --timeout-ms 5000 2>/dev/null > "$TEMP_FILE"

# Считаем строки (каждое сообщение = 1 строка JSON)
TOTAL=$(grep -c '{' "$TEMP_FILE" || echo "0")

echo "✅ Total messages in topic: $TOTAL"
echo ""

if [ "$TOTAL" -gt 0 ]; then
    echo "📋 Messages content:"
    echo "-----------------------------------"
    cat -n "$TEMP_FILE"
    echo "-----------------------------------"
    echo ""

    echo "📊 Unique Order IDs:"
    grep -o '"orderId":"[^"]*"' "$TEMP_FILE" | sort | uniq -c | while read count pattern; do
        order_id=$(echo "$pattern" | cut -d'"' -f4)
        echo "   • $order_id: $count occurrence(s)"
    done
else
    echo "⚠️  No messages found in topic"
fi

echo ""
echo "📄 Raw data saved to: $TEMP_FILE"
echo ""
echo "========================================="