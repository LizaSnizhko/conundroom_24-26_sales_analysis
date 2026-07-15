--- Query to calculate total monthly revenue (bookings + on-site sales) and booking counts

CREATE OR REPLACE VIEW monthly_performance AS
    WITH on_site_sales_summary AS (
        SELECT 
            DATE_TRUNC('month',date) as month,
            SUM(on_site_sales.corrected_total_net) AS total_net
        FROM on_site_sales  
        GROUP BY DATE_TRUNC('month',date)
    ),
    bookings_summary AS (
        SELECT 
            DATE_TRUNC('month',start_time) as month,
            SUM(corrected_total_net) AS total_net,
            COUNT(*) FILTER(WHERE NOT (status = 'canceled' AND corrected_total_net <= 0)) AS total_bookings
        FROM bookings
        GROUP BY DATE_TRUNC('month',start_time)
    )

    SELECT 
        bookings_summary.month,
        bookings_summary.total_net + COALESCE(on_site_sales_summary.total_net,0) AS total_revenue,
        bookings_summary.total_bookings
    FROM bookings_summary 
    LEFT JOIN on_site_sales_summary USING(month)
    ORDER BY month;



SELECT * FROM monthly_performance
