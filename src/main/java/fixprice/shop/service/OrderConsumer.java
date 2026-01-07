package fixprice.shop.service;

import fixprice.shop.model.OrderEvent;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.kafka.support.KafkaHeaders;
import org.springframework.messaging.handler.annotation.Header;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.stereotype.Service;

import java.util.concurrent.atomic.AtomicLong;

@Service
public class OrderConsumer {

    private static final Logger log = LoggerFactory.getLogger(OrderConsumer.class);

    // Счетчик обработанных сообщений
    private final AtomicLong processedCount = new AtomicLong(0);

    @KafkaListener(
        topics = "orders",
        groupId = "order-consumer-group",
        containerFactory = "kafkaListenerContainerFactory"
    )
    public void consumeOrder(
            @Payload OrderEvent order,
            @Header(KafkaHeaders.RECEIVED_PARTITION) int partition,
            @Header(KafkaHeaders.OFFSET) long offset,
            @Header(KafkaHeaders.RECEIVED_TOPIC) String topic,
            Acknowledgment acknowledgment
    ) {
        try {
            // Обработка сообщения
            long count = processedCount.incrementAndGet();

            log.info(
                "✅ [{}] Received order #{}: orderId={}, userId={}, amount={}, partition={}, offset={}",
                count,
                order.orderId(),
                order.orderId(),
                order.userId(),
                order.amount(),
                partition,
                offset
            );

            // Здесь может быть бизнес-логика
            // processOrder(order);

            // Manual commit после успешной обработки
            acknowledgment.acknowledge();

            log.debug("✓ Message committed: orderId={}, offset={}", order.orderId(), offset);

        } catch (Exception e) {
            log.error(
                "❌ Error processing order: orderId={}, partition={}, offset={}",
                order.orderId(),
                partition,
                offset,
                e
            );
            // Не делаем acknowledge при ошибке
            // Сообщение будет перечитано
        }
    }

    /**
     * Получить количество обработанных сообщений
     */
    public long getProcessedCount() {
        return processedCount.get();
    }

    /**
     * Сбросить счетчик (для тестирования)
     */
    public void resetCounter() {
        processedCount.set(0);
        log.info("🔄 Message counter reset to 0");
    }
}