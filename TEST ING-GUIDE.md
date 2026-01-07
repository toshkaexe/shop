# 📋 Testing Guide - Kafka Message Verification

## Текущее состояние

В топике `orders` **6 сообщений**:
- `123`: 1 сообщение
- `ORD-003`: 3 сообщения (дубликаты)
- `TEST-001`: 1 сообщение
- `VERIFY-001`: 1 сообщение

---

## Способ 1: Bash скрипт (быстрая проверка)

### Подсчет всех сообщений

```bash
cd /Users/azeltser/IdeaProjects/shop
./count-messages.sh
```

**Что показывает:**
- Общее количество сообщений
- Список всех orderId с количеством повторений
- Полное содержимое каждого сообщения

---

## Способ 2: REST API /stats endpoint

### Проверка через приложение

```bash
# Получить статистику обработанных Consumer сообщений
curl http://localhost:8080/stats

# Ответ:
{
  "processedMessages": 6,
  "consumerGroup": "order-consumer-group",
  "topic": "orders"
}
```

### Сброс счетчика

```bash
curl -X POST http://localhost:8080/stats/reset
```

---

## Способ 3: Kafka CLI команды

### Подсчет сообщений в топике

```bash
docker exec kafka /opt/kafka/bin/kafka-run-class.sh kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 \
  --topic orders \
  --time -1
```

### Чтение всех сообщений

```bash
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --from-beginning \
  --timeout-ms 5000
```

### Проверка Consumer Group состояния

```bash
docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group order-consumer-group \
  --describe
```

---

## Способ 4: Postman Collection Runner

### Отправка множества сообщений

1. Откройте Postman Collection `Shop Orders API`
2. Выберите запрос `Bulk Order Test`
3. Нажмите **Run**
4. Установите **Iterations: 10**
5. Нажмите **Run Shop Orders API**

### Проверка результатов

После отправки проверьте:

```bash
# Общее количество
./count-messages.sh

# Или через API
curl http://localhost:8080/stats
```

---

## Способ 5: Логи Consumer

### Проверка обработанных сообщений в реальном времени

```bash
# Следить за логами Consumer
tail -f /tmp/shop-app.log | grep "Received order"
```

Вы увидите:
```
✅ [1] Received order #1: orderId=BULK-001, userId=USER-42, amount=99.99, partition=0, offset=5
✅ [2] Received order #2: orderId=BULK-002, userId=USER-43, amount=149.50, partition=1, offset=3
```

---

## Полный тестовый сценарий

### 1. Очистка топика (опционально)

```bash
# Удалить и пересоздать топик
docker exec kafka /opt/kafka/bin/kafka-topics.sh --delete \
  --bootstrap-server localhost:9092 \
  --topic orders

docker exec kafka /opt/kafka/bin/kafka-topics.sh --create \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --partitions 3 \
  --replication-factor 1
```

### 2. Сброс Consumer offset (начать читать заново)

```bash
docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group order-consumer-group \
  --reset-offsets \
  --to-earliest \
  --topic orders \
  --execute
```

### 3. Отправка тестовых сообщений

```bash
for i in {1..10}; do
  curl -X POST http://localhost:8080/orders \
    -H "Content-Type: application/json" \
    -d "{\"orderId\":\"TEST-$i\",\"userId\":\"USER-$i\",\"amount\":$((i * 100)).00,\"createdAt\":\"2026-01-07T15:00:00Z\"}"
  echo "Sent message $i"
  sleep 0.5
done
```

### 4. Проверка результатов

```bash
# Способ A: Скрипт
./count-messages.sh

# Способ B: API
curl http://localhost:8080/stats

# Способ C: Kafka CLI
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --from-beginning \
  --timeout-ms 5000 | wc -l
```

**Все три способа должны показать одинаковое число: 10 сообщений**

---

## Troubleshooting

### Сообщения не читаются Consumer

```bash
# Проверить, запущен ли Consumer
curl http://localhost:8080/stats

# Проверить consumer group
docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --list
```

### Разные числа в топике и Consumer

Возможные причины:
1. **Consumer group уже читал часть сообщений** → Сбросьте offset
2. **Consumer не запущен** → Перезапустите приложение
3. **Ошибки в Consumer** → Проверьте логи приложения

### Проверка Lag (отставание)

```bash
docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group order-consumer-group \
  --describe
```

Колонка **LAG** показывает, сколько сообщений не обработано.
- `LAG = 0` → Все сообщения обработаны ✅
- `LAG > 0` → Есть необработанные сообщения ⚠️

---

## Итоговая проверка

```bash
# 1. Отправить 5 новых сообщений через Postman

# 2. Подождать 2 секунды
sleep 2

# 3. Проверить все способы:
./count-messages.sh                        # Должно показать +5 сообщений
curl http://localhost:8080/stats           # processedMessages увеличится на 5
docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group order-consumer-group \
  --describe                                # LAG должен быть 0
```

**Если все три проверки сходятся → все сообщения получены и обработаны!** ✅

---

## Автоматизация проверки

Создайте скрипт `verify-complete.sh`:

```bash
#!/bin/bash

echo "🔍 Verifying message delivery..."

# Количество в топике
TOPIC_COUNT=$(docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh \
  --bootstrap-server localhost:9092 \
  --topic orders \
  --from-beginning \
  --timeout-ms 3000 2>/dev/null | wc -l | tr -d ' ')

# Количество обработанных Consumer
PROCESSED=$(curl -s http://localhost:8080/stats | grep -o '"processedMessages":[0-9]*' | cut -d':' -f2)

# LAG
LAG=$(docker exec kafka /opt/kafka/bin/kafka-consumer-groups.sh \
  --bootstrap-server localhost:9092 \
  --group order-consumer-group \
  --describe 2>/dev/null | grep "orders" | awk '{sum += $6} END {print sum}')

echo ""
echo "📊 Results:"
echo "   Messages in topic: $TOPIC_COUNT"
echo "   Processed by consumer: $PROCESSED"
echo "   Lag: ${LAG:-0}"
echo ""

if [ "$LAG" = "0" ] || [ -z "$LAG" ]; then
    echo "✅ SUCCESS: All messages delivered and processed!"
else
    echo "⚠️  WARNING: $LAG messages not processed yet"
fi
```

Запустите: `chmod +x verify-complete.sh && ./verify-complete.sh`

---

**🎉 Теперь у вас есть полный набор инструментов для проверки доставки сообщений Kafka!**