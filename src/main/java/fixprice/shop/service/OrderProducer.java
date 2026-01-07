package fixprice.shop.service;

import fixprice.shop.model.OrderEvent;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;
import org.springframework.kafka.core.KafkaTemplate;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.concurrent.CompletableFuture;

@Service
public class OrderProducer {

    private static final Logger log = LoggerFactory.getLogger(OrderProducer.class);
    private static final String TOPIC_ORDERS = "orders";
    private final KafkaTemplate<String, OrderEvent> kafkaTemplate;

    public OrderProducer(KafkaTemplate<String, OrderEvent> kafkaTemplate) {
        this.kafkaTemplate = kafkaTemplate;
    }

    /**
     * Simple fire-and-forget send
     */
    public void send(OrderEvent event) {
        // key = orderId → гарантирует ordering
        kafkaTemplate.send(TOPIC_ORDERS, event.orderId(), event);
    }

    /**
     * Send message with callback
     */
    public void sendWithCallback(OrderEvent event) {
        CompletableFuture<SendResult<String, OrderEvent>> future =
                kafkaTemplate.send(TOPIC_ORDERS, event.orderId(), event);

        future.whenComplete((result, ex) -> {
            if (ex == null) {
                log.info(
                        "Order sent successfully. orderId={}, partition={}, offset={}",
                        event.orderId(),
                        result.getRecordMetadata().partition(),
                        result.getRecordMetadata().offset()
                );
            } else {
                log.error(
                        "Failed to send order. orderId={}",
                        event.orderId(),
                        ex
                );
            }
        });
    }
}
