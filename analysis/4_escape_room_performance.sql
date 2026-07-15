-- Quary to answer the following questions: Which escape rooms generate the highest revenue, and does popularity correlate with revenue? 

CREATE OR REPLACE VIEW room_performance AS
    WITH on_site_sales_summary AS (
        SELECT 
            COALESCE(booking_categories.escape_room, 'Unsorted') AS escape_room,
            SUM(on_site_sales.corrected_total_net) AS total_net,
            SUM(count) AS total_players
        FROM on_site_sales  
        LEFT JOIN booking_categories 
            ON on_site_sales.item = booking_categories.on_site_sales_corresponding_item
        GROUP BY booking_categories.escape_room
    ),
    bookings_summary AS (
        SELECT 
            escape_room,
            location,
            SUM(corrected_total_net) AS total_net,
            SUM(participants) FILTER(WHERE NOT (status = 'canceled')) AS total_players,
            COUNT(*) FILTER(WHERE NOT (status = 'canceled' AND corrected_total_net <= 0)) 
                AS total_online_bookings
        FROM bookings
        GROUP BY escape_room, location
    )

    SELECT 
        bookings_summary.escape_room,
        bookings_summary.location,
        bookings_summary.total_net + 
            COALESCE(on_site_sales_summary.total_net,0) AS total_revenue,
        bookings_summary.total_players + 
            COALESCE(on_site_sales_summary.total_players,0) AS total_players,
        bookings_summary.total_online_bookings,
        ROUND((bookings_summary.total_net + COALESCE(on_site_sales_summary.total_net,0))/bookings_summary.total_online_bookings,2) AS average_revenue_per_booking
    FROM bookings_summary
    LEFT JOIN on_site_sales_summary USING(escape_room)
    WHERE escape_room IN (
        SELECT escape_room FROM booking_categories WHERE booking_category = 'Escape Room'
    );
