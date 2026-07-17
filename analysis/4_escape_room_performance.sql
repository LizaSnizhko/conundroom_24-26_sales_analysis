-- Quary to answer the following questions: Which escape rooms generate the highest revenue, and does popularity correlate with revenue? 

CREATE OR REPLACE VIEW room_performance AS
    WITH on_site_sales_summary AS (
        SELECT 
            COALESCE(booking_categories.escape_room, 'Unsorted') AS escape_room,
            CASE WHEN date >= '2025-07-01' THEN 'Jul 2025 - Jun 2026' ELSE 'Jul 2024 - Jun 2025' 
                END AS period,
            SUM(on_site_sales.corrected_total_net) AS total_net,
            SUM(count) AS total_players
        FROM on_site_sales  
        LEFT JOIN booking_categories 
            ON on_site_sales.item = booking_categories.on_site_sales_corresponding_item
        GROUP BY booking_categories.escape_room, period
    ),
    bookings_summary AS (
        SELECT 
            escape_room,
            location,
            CASE WHEN start_time >= '2025-07-01' THEN 'Jul 2025 - Jun 2026' ELSE 'Jul 2024 - Jun 2025' END AS period,
            SUM(corrected_total_net) AS total_net,
            SUM(participants) FILTER(WHERE status <> 'canceled') AS total_players,
            COUNT(*) FILTER(WHERE status <> 'canceled') AS total_bookings
        FROM bookings
        GROUP BY escape_room, location, period
    )

    SELECT 
        bookings_summary.escape_room,
        bookings_summary.location,
         bookings_summary.period,
        bookings_summary.total_net + 
            COALESCE(on_site_sales_summary.total_net,0) AS total_revenue,
        bookings_summary.total_players + 
            COALESCE(on_site_sales_summary.total_players,0) AS total_players,
        bookings_summary.total_bookings,
        ROUND((bookings_summary.total_net + COALESCE(on_site_sales_summary.total_net,0))/
            bookings_summary.total_bookings,2) AS average_revenue_per_booking
    FROM bookings_summary
    LEFT JOIN on_site_sales_summary USING(escape_room, period)
    WHERE escape_room IN (
        SELECT escape_room FROM booking_categories WHERE booking_category = 'Escape Room'
    );

SELECT * FROM room_performance
