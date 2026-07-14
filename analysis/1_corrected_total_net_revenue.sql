----1---- Query to correct the total_revenue for online sales

ALTER TABLE bookings
ADD COLUMN corrected_total_net NUMERIC(10,2);


-- a query of incorrectly paid bookings 
SELECT booking_number, total_net, total_paid
FROM bookings
WHERE total_net >= total_paid 
   AND total_paid NOT IN (0.00, 50.00, 100.00)


UPDATE bookings 
SET corrected_total_net = 
    CASE WHEN total_net >= total_paid 
    AND total_paid NOT IN (0.00, 50.00, 100.00)
         THEN ROUND(total_paid/1.079, 2)
    ELSE total_net
    END;


--checking the result
SELECT corrected_total_net, total_net, total_paid
FROM bookings
WHERE total_net!=corrected_total_net


-----2---- Query to correct the total_revenue for on-site payments 

--fixed net_sales column to 
ALTER TABLE on_site_sales
ADD COLUMN corrected_total_net NUMERIC(10,2);

UPDATE on_site_sales
SET corrected_total_net = 
    CASE 
        WHEN net_sales < 0 THEN 0
        WHEN tax = 0 AND gross_sales % 25 != 0 AND net_sales % 1 = 0 THEN ROUND((net_sales/1.079)::numeric, 2)
        WHEN (item = 'Axe-Throwing - 1 hour' OR item = 'Corporate Event Ticket' OR item = 'ADD Corporate Event') AND count >= 10 THEN 0
        ELSE net_sales
    END


--checking the result
SELECT *
FROM on_site_sales