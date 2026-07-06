ALTER TABLE bookings
ADD COLUMN corrected_total_net NUMERIC(10,2);


UPDATE bookings 
SET corrected_total_net = 
    CASE WHEN total_net >= total_paid 
    AND total_paid NOT IN (0.00, 50.00, 100.00)
         THEN ROUND(total_paid/1.079, 2)
    ELSE total_net
    END;


--check the result
SELECT corrected_total_net, total_net, total_paid
FROM bookings
WHERE total_net!=corrected_total_net


-- incorrectly paid bookings 
SELECT booking_number, total_net, total_paid
FROM bookings
WHERE total_net >= total_paid 
   AND total_paid NOT IN (0.00, 50.00, 100.00)