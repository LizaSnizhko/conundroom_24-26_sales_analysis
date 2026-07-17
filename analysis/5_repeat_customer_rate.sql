-- Calculations of repeat customer rate (out 
--of everyone who came at least once, what % came back for a second (or more) visit?)

WITH returning_customers AS (
    SELECT 
        LOWER(email_address) as email,
        COUNT(*) as total_bookings
    FROM bookings
    WHERE 
        (LOWER(email_address) not in ('liza@conundroom.us',
            'test@conundroom.us','info@conundroom.us','anna.ryabtsev@conundroom.us', 
            'test@test.com','anna.ryabtseva@gmail.com','snizhko.liza@gmail.com')) 
        AND start_time >='2025-07-01'
        AND status <> 'canceled'
        AND (corrected_total_net > 0 OR (corrected_total_net = 0 AND coupons IS NOT NULL))
    GROUP BY LOWER(email_address))

SELECT ROUND(COUNT(*) FILTER (WHERE total_bookings>= 2) / COUNT(*)::numeric, 
    4) as repeat_customer_rate_pct
FROM returning_customers