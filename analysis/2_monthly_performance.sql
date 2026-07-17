--- Query to calculate total monthly revenue (bookings + on-site sales) and booking counts

CREATE OR REPLACE VIEW monthly_performance AS
    WITH on_site_sales_summary AS (
        SELECT 
            DATE_TRUNC('month', date) as month,
            SUM(corrected_total_net) AS total_net,
            SUM(count) FILTER 
                (WHERE item in (SELECT on_site_sales_corresponding_item 
                FROM booking_categories 
                WHERE on_site_sales_corresponding_item <> 'Unsorted')) AS total_players
        FROM on_site_sales  
        GROUP BY DATE_TRUNC('month', date)
    ),
    bookings_summary AS (
        SELECT 
            DATE_TRUNC('month',start_time) as month,
            SUM(corrected_total_net) AS total_net,
            SUM(participants) FILTER(WHERE status <> 'canceled') AS total_players,
            COUNT(*) FILTER(WHERE status <> 'canceled') AS total_bookings
        FROM bookings
        GROUP BY DATE_TRUNC('month',start_time)
    )

    SELECT 
        bookings_summary.month,
        bookings_summary.total_net + COALESCE(on_site_sales_summary.total_net,0) AS total_revenue,
        bookings_summary.total_bookings,
        bookings_summary.total_players + on_site_sales_summary.total_players AS total_players
    FROM bookings_summary 
    LEFT JOIN on_site_sales_summary USING(month)
    ORDER BY month;

SELECT * FROM monthly_performance
