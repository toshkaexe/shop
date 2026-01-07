#!/bin/bash

# ========================================
# Kafka Topic Quick Commands
# ========================================

KAFKA_CONTAINER="kafka"
BOOTSTRAP_SERVER="localhost:9092"
TOPIC="orders"

echo "========================================="
echo "Kafka Topic Commands - Quick Reference"
echo "========================================="
echo ""

# Функция для отображения меню
show_menu() {
    echo "Choose an action:"
    echo ""
    echo "  1) List all topics"
    echo "  2) Describe topic '$TOPIC'"
    echo "  3) Count messages in topic"
    echo "  4) Read all messages"
    echo "  5) Read last 10 messages"
    echo "  6) Create new topic"
    echo "  7) Delete topic '$TOPIC'"
    echo "  8) Reset consumer group offsets"
    echo "  9) Show consumer group status"
    echo " 10) Monitor topic (live)"
    echo ""
    echo "  0) Exit"
    echo ""
    echo -n "Enter choice [0-10]: "
}

# 1. List all topics
list_topics() {
    echo "📋 All Kafka topics:"
    docker exec $KAFKA_CONTAINER /opt/kafka/bin/kafka-topics.sh \
        --list \
        --bootstrap-server $BOOTSTRAP_SERVER
}

# 2. Describe topic
describe_topic() {
    echo "📊 Topic details: $TOPIC"
    docker exec $KAFKA_CONTAINER /opt/kafka/bin/kafka-topics.sh \
        --describe \
        --bootstrap-server $BOOTSTRAP_SERVER \
        --topic $TOPIC
}

# 3. Count messages
count_messages() {
    echo "🔢 Counting messages in topic '$TOPIC'..."
    docker exec $KAFKA_CONTAINER /opt/kafka/bin/kafka-run-class.sh \
        kafka.tools.GetOffsetShell \
        --broker-list $BOOTSTRAP_SERVER \
        --topic $TOPIC \
        --time -1 | awk -F':' '{print "Partition " $2 ": " $3 " messages"; sum += $3} END {print "\nTotal: " sum " messages"}'
}

# 4. Read all messages
read_all_messages() {
    echo "📖 Reading all messages from topic '$TOPIC':"
    echo "------------------------------------"
    docker exec $KAFKA_CONTAINER /opt/kafka/bin/kafka-console-consumer.sh \
        --bootstrap-server $BOOTSTRAP_SERVER \
        --topic $TOPIC \
        --from-beginning \
        --timeout-ms 5000 2>/dev/null | cat -n
    echo "------------------------------------"
}

# 5. Read last N messages
read_last_messages() {
    local n=${1:-10}
    echo "📖 Reading last $n messages from topic '$TOPIC':"
    echo "------------------------------------"
    docker exec $KAFKA_CONTAINER /opt/kafka/bin/kafka-console-consumer.sh \
        --bootstrap-server $BOOTSTRAP_SERVER \
        --topic $TOPIC \
        --from-beginning \
        --max-messages $n \
        --timeout-ms 3000 2>/dev/null | tail -$n | cat -n
    echo "------------------------------------"
}

# 6. Create new topic
create_topic() {
    echo -n "Enter new topic name: "
    read new_topic
    echo -n "Enter number of partitions [3]: "
    read partitions
    partitions=${partitions:-3}

    echo "Creating topic '$new_topic' with $partitions partitions..."
    docker exec $KAFKA_CONTAINER /opt/kafka/bin/kafka-topics.sh \
        --create \
        --bootstrap-server $BOOTSTRAP_SERVER \
        --topic $new_topic \
        --partitions $partitions \
        --replication-factor 1

    if [ $? -eq 0 ]; then
        echo "✅ Topic '$new_topic' created successfully!"
    else
        echo "❌ Failed to create topic"
    fi
}

# 7. Delete topic
delete_topic() {
    echo "⚠️  WARNING: This will delete topic '$TOPIC' and all its data!"
    echo -n "Are you sure? (yes/no): "
    read confirm

    if [ "$confirm" = "yes" ]; then
        docker exec $KAFKA_CONTAINER /opt/kafka/bin/kafka-topics.sh \
            --delete \
            --bootstrap-server $BOOTSTRAP_SERVER \
            --topic $TOPIC
        echo "✅ Topic deleted (if existed)"
    else
        echo "❌ Deletion cancelled"
    fi
}

# 8. Reset consumer group offsets
reset_offsets() {
    local group="order-consumer-group"
    echo "🔄 Resetting offsets for consumer group '$group' to earliest..."
    docker exec $KAFKA_CONTAINER /opt/kafka/bin/kafka-consumer-groups.sh \
        --bootstrap-server $BOOTSTRAP_SERVER \
        --group $group \
        --reset-offsets \
        --to-earliest \
        --topic $TOPIC \
        --execute
}

# 9. Show consumer group status
show_consumer_status() {
    echo "📊 Consumer group status:"
    docker exec $KAFKA_CONTAINER /opt/kafka/bin/kafka-consumer-groups.sh \
        --bootstrap-server $BOOTSTRAP_SERVER \
        --group order-consumer-group \
        --describe
}

# 10. Monitor topic (live)
monitor_topic() {
    echo "📡 Monitoring topic '$TOPIC' (Ctrl+C to stop)..."
    echo ""

    while true; do
        clear
        echo "=== Kafka Topic Monitor: $TOPIC ==="
        echo "Time: $(date)"
        echo ""

        # Partition info
        docker exec $KAFKA_CONTAINER /opt/kafka/bin/kafka-run-class.sh \
            kafka.tools.GetOffsetShell \
            --broker-list $BOOTSTRAP_SERVER \
            --topic $TOPIC \
            --time -1 | awk -F':' '{print "Partition " $2 ": " $3 " messages"; sum += $3} END {print "\nTotal: " sum " messages"}'

        echo ""
        echo "Refreshing in 3 seconds..."
        sleep 3
    done
}

# Main loop
while true; do
    show_menu
    read choice
    echo ""

    case $choice in
        1) list_topics ;;
        2) describe_topic ;;
        3) count_messages ;;
        4) read_all_messages ;;
        5) read_last_messages 10 ;;
        6) create_topic ;;
        7) delete_topic ;;
        8) reset_offsets ;;
        9) show_consumer_status ;;
        10) monitor_topic ;;
        0) echo "Goodbye!"; exit 0 ;;
        *) echo "❌ Invalid choice. Please try again." ;;
    esac

    echo ""
    echo "Press Enter to continue..."
    read
    clear
done
