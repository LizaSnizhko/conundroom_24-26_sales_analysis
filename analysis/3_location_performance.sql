-- Query to calculate monthly revenue by location (bookings + on-site sales combined)

--Added a location column on booking_categories, which is inferred from matching bookings
ALTER TABLE booking_categories
ADD COLUMN location TEXT;

UPDATE booking_categories
SET location = CASE
    WHEN escape_room in (
        SELECT escape_room FROM bookings
    )
    THEN (
        SELECT location FROM bookings 
        WHERE bookings.escape_room = booking_categories.escape_room
            AND booking_categories.booking_category = 'Escape Room'
        LIMIT 1
    )
    ELSE NULL
    END

---Added a location column on on_site_sales by using booking_categories mapping first, then device_id and item/amount fallback rules
ALTER TABLE on_site_sales
ADD COLUMN location TEXT;

UPDATE on_site_sales
SET location = CASE 
    WHEN item in (SELECT on_site_sales_corresponding_item 
                    FROM booking_categories
                    WHERE on_site_sales_corresponding_item <> 'Unsorted') 
    THEN (
        SELECT location
        FROM booking_categories
        WHERE booking_categories.on_site_sales_corresponding_item = on_site_sales.item
        LIMIT 1
    )
    WHEN device_id IN ('Ethan‚Äôs iPhone', 'Square Terminal 4065') 
        OR item LIKE 'Party Room%' 
        OR item LIKE 'Party room%' 
        OR item = 'Wand' 
        OR item = 'Party Package' 
        OR (item = 'Custom Amount' AND (
            gross_sales IN (554.24,631.93,424.76,530.50,614.66,90.00)
        )) THEN 'SoM'
    WHEN device_id = 'Square Terminal 3738' OR
        (item = 'Custom Amount' AND gross_sales in (504.24,320.81,573.30, 471.87)) THEN 'Avalon'
    WHEN device_id IN ('Conundroom‚Äôs iPad', 'Conundroom','Square Terminal 1554') OR (item = 'Custom Amount' OR item = 'Event Ticket') AND (
            gross_sales IN (429.00,267.23))
    THEN 'Downtown'
END;

--Final view 
CREATE OR REPLACE VIEW location_performance AS
    WITH on_site_sales_summary AS (
        SELECT 
            DATE_TRUNC('month',on_site_sales.date) as month,
            SUM(on_site_sales.corrected_total_net) AS total_net,
            SUM(CASE WHEN booking_categories.location = 'Avalon' THEN corrected_total_net END) AS Avalon,
            SUM(CASE WHEN booking_categories.location = 'Downtown' THEN corrected_total_net END) AS Downtown,
            SUM(CASE WHEN booking_categories.location = 'SoM' THEN corrected_total_net END) AS SoM
        FROM on_site_sales 
        LEFT JOIN booking_categories ON booking_categories.on_site_sales_corresponding_item = on_site_sales.item
        GROUP BY DATE_TRUNC('month',date)
    ),
    bookings_summary AS (
        SELECT 
            DATE_TRUNC('month',start_time) as month,
            SUM(corrected_total_net) AS total_net,
            SUM(CASE WHEN location = 'Avalon' THEN corrected_total_net END) AS Avalon,
            SUM(CASE WHEN location = 'Downtown' THEN corrected_total_net END) AS Downtown,
            SUM(CASE WHEN location = 'SoM' THEN corrected_total_net END) AS SoM
        FROM bookings
        GROUP BY DATE_TRUNC('month',start_time)
    )

    SELECT 
        bookings_summary.month,
        bookings_summary.Avalon + COALESCE(on_site_sales_summary.Avalon,0) AS Avalon,
        bookings_summary.Downtown + COALESCE(on_site_sales_summary.Downtown,0) AS Downtown,
        bookings_summary.SoM + COALESCE(on_site_sales_summary.SoM,0) AS SoM
    FROM 
        bookings_summary
    JOIN on_site_sales_summary USING(month)
    ORDER BY month;

