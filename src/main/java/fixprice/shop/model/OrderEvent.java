package fixprice.shop.model;

import java.math.BigDecimal;
import java.time.Instant;

public record OrderEvent(
        String orderId,
        String userId,
        BigDecimal amount,
        Instant createdAt
) {}
