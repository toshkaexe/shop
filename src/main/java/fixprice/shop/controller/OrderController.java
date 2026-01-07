package fixprice.shop.controller;

import fixprice.shop.model.OrderEvent;
import fixprice.shop.service.OrderProducer;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/orders")
public class OrderController {

    private final OrderProducer orderProducer;

    public OrderController(OrderProducer orderProducer) {
        this.orderProducer = orderProducer;
    }

    @PostMapping
    public ResponseEntity<Void> createOrder(@RequestBody OrderEvent event) {
        orderProducer.sendWithCallback(event);
        return ResponseEntity.accepted().build();
    }
}

