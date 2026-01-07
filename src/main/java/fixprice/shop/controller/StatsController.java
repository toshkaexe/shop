package fixprice.shop.controller;

import fixprice.shop.service.OrderConsumer;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/stats")
public class StatsController {

    private final OrderConsumer orderConsumer;

    public StatsController(OrderConsumer orderConsumer) {
        this.orderConsumer = orderConsumer;
    }

    /**
     * Получить статистику обработанных сообщений
     */
    @GetMapping
    public ResponseEntity<Map<String, Object>> getStats() {
        return ResponseEntity.ok(Map.of(
            "processedMessages", orderConsumer.getProcessedCount(),
            "consumerGroup", "order-consumer-group",
            "topic", "orders"
        ));
    }

    /**
     * Сбросить счетчик сообщений
     */
    @PostMapping("/reset")
    public ResponseEntity<Map<String, String>> resetStats() {
        orderConsumer.resetCounter();
        return ResponseEntity.ok(Map.of(
            "message", "Counter reset successfully",
            "processedMessages", "0"
        ));
    }
}