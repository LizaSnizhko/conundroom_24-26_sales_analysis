# Conundroom Escape Rooms Sales Analysis

## Project Overview

This project analyzes sales and booking data for Conundroom Escape Rooms from July 1, 2025 through June 30, 2026. 

The goal is to explore booking trends, revenue, single escape room performance, customer behavior, compare to the previous year, and see business performance across all three locations using SQL(PostgreSQL) and Tableau. The deliverable of this project would be a complete Conundroom Sales Dashboard for July 2025 - June 2026


## Data
The analysis uses real sales and revenue data exported from the Bookeo booking platform (online sales) and Square (on-site sales) for three Conundroom locations. The datasets contain booking and customer information, as well as payments, for 2 years (July 1, 2024 through June 30, 2026).

***NOTE: To maintain confidentiality, each revenue figure was multiplied by a single constant, a hidden value using SQL.***

## Tools
* SQL (PostgreSQL)
* Tableau
* Excel (+Power Query)

## 0. Data Preparation and Cleaning

### "Bookings" Dataset Prep and Cleaning

I loaded data for each location, for each quarter, from July 1st 2024 to June 30th 2026. Bookeo only allows downloading one report per quarter, for one location at a time, so I exported 24 separate files (3 locations x 8 quarters) and combined them using Power Query.

Since some columns were location-specific, I removed the unnecessary ones and merged the remaining values into single columns. I added a `location` column with the name of each of the three locations, then combined everything into one Excel file, sorted by date.

I also manually corrected a few edge cases: bookings where a large client paid for two locations in a single transaction (so each location could still be credited properly), and 7 offsite events that were missing from the original export.

Once the data was clean, I created the `bookings` table in PostgreSQL:

```sql
CREATE TABLE bookings (
    booking_number          TEXT PRIMARY KEY,
    start_time              TIMESTAMP,
    end_time                TIMESTAMP,
    participants            INTEGER,
    escape_room              TEXT,
    -- full schema in /analysis/0_create_tables.sql
);
```

**Cleaning: fixing underpaid or misrecorded transactions**

I found 39 bookings where the amount paid did not match the amount owed, likely due to on-site payments not syncing with the booking platform:

```sql
SELECT booking_number, total_net, total_paid
FROM bookings
WHERE total_net >= total_paid 
   AND total_paid NOT IN (0.00, 50.00, 100.00);
```

$50 and $100 are standard deposit amounts we charge for party bookings, where the rest is paid on-site, so those due amounts are expected and not an error. For the other 39 bookings, I created a `corrected_total_net` column using the actual amount paid instead of the recorded total, so revenue analysis reflects real payments rather than system mismatches. Finally, I trimmed whitespace from escape room names to avoid duplicate categories caused by inconsistent formatting:

```sql
ALTER TABLE bookings
ADD COLUMN corrected_total_net NUMERIC(10,2);

UPDATE bookings 
SET corrected_total_net = 
    CASE WHEN total_net >= total_paid 
              AND total_paid NOT IN (0.00, 50.00, 100.00)
         THEN ROUND(total_paid / 1.079, 2)
         ELSE total_net
    END;

UPDATE bookings
SET escape_room = TRIM(escape_room);
```

### "On-Site Sales" Dataset Prep and Cleaning

On-site sales are transactions processed through Square, covering walk-in games, players added on-site, merchandise, gift cards, and occasionally over-the-phone payments. Phone payments are easier to process through Square since Bookeo, our booking platform, does not support that feature directly. When a manager took a payment this way, they would still have to manually create a matching booking in Bookeo, which meant every phone payment created a duplicate record between the two systems. I identified these duplicates manually and removed them from the on-site sales dataset in Excel before building the SQL table.

I also removed a number of unnecessary columns before creating the table.

**Mapping item names to escape rooms**

Each on-site transaction has an item name, but these names rarely matched the escape room names used in the bookings dataset. For example, the escape room "Alice in Wonderland" would appear as the item "ADD Alice Player" in Square. I mapped each item name to its corresponding escape room so that I could analyze single-room performance and correctly assign a location to each transaction.

Some transactions had no item name at all, since they were entered as a custom amount, making it impossible to tell what was actually purchased from the data alone. Most of these came from a payment pattern we used to follow: customers would pay a $50 or $100 deposit through Bookeo, then pay the remaining $300–$600 on-site. To resolve these, I manually reviewed each custom-amount transaction, cross-referenced it against our Google Calendar to identify which party it belonged to, and assigned it to the correct location by hand.

**Assigning a location to each transaction**

Location assignment turned out to be one of the largest cleanup challenges. My original plan was to map each transaction's `device_id` directly to a location, but in practice there were at least 15 different device IDs in use, some appearing frequently, others only a handful of times. I manually mapped each device name to the location it most likely belonged to, cross-checked against the item being sold.

After this process, 27 transactions remained undefined. These had both a custom-amount item and either a missing or unrecognizable device ID, typically cases where an employee processed the payment through Square on their own personal phone. Since there was no reliable way to trace these back to a specific location, I excluded them from the location-level analysis.

Here is the code I used to backfill location on the `on_site_sales` table:

```sql
ALTER TABLE on_site_sales
ADD COLUMN location TEXT;

UPDATE on_site_sales
SET location = CASE 
    WHEN item IN (SELECT on_site_sales_corresponding_item FROM booking_categories WHERE on_site_sales_corresponding_item <> 'Unsorted') 
        THEN (SELECT location FROM booking_categories WHERE booking_categories.on_site_sales_corresponding_item = on_site_sales.item LIMIT 1)
    WHEN device_id IN ('Ethan's iPhone', 'Square Terminal 4065') OR item LIKE 'Party Room%' THEN 'SoM'
    WHEN device_id = 'Square Terminal 3738' THEN 'Avalon'
    WHEN device_id IN ('Conundroom's iPad', 'Square Terminal 1554') THEN 'Downtown'
    -- full logic, including custom-amount matching by gross_sales, in /analysis/0_create_tables.sql
END;
```

### "Booking Categories" Table Creation and Prep

To connect on-site sales, bookings, and locations into one consistent structure, I built a lookup table called `booking_categories`. This table maps each escape room to its booking category (e.g. Escape Room vs. Special Event) and to its corresponding Square item name, which is what makes the location-mapping logic above possible.

```sql
CREATE TABLE booking_categories (
    escape_room TEXT,
    booking_category TEXT
);

ALTER TABLE booking_categories
ADD COLUMN on_site_sales_corresponding_item TEXT;

UPDATE booking_categories
SET on_site_sales_corresponding_item =
CASE
    WHEN escape_room = 'Alice in Wonderland' THEN 'ADD Alice player'
    WHEN escape_room = 'The Vault' THEN 'ADD The Vault player'
    WHEN escape_room = 'Red vs. Blue: BOMB Defuse Challenge' THEN 'Special Event'
    ELSE 'Unsorted'
    -- full mapping in /analysis/0_create_tables.sql
END;
```

Once each escape room had a corresponding Square item name, I backfilled a `location` column onto `booking_categories` itself, inferred from the location already recorded in the `bookings` table:

```sql
ALTER TABLE booking_categories
ADD COLUMN location TEXT;

UPDATE booking_categories
SET location = (
    SELECT location FROM bookings 
    WHERE bookings.escape_room = booking_categories.escape_room
      AND booking_categories.booking_category = 'Escape Room'
    LIMIT 1
);
```

This table became the key bridge between the two data sources: with it, every on-site transaction could be traced back to a specific escape room, and from there, to its location, which made combined revenue analysis across both platforms possible.


## 1. Revenue Performance View

After cleaning the data, I set out to answer: ** How have booking volume and revenue changed over time (monthly) from July 2025 through June 2026?**

### Monthly Revenue and Booking Volume

This view combines online bookings and on-site sales into total monthly revenue, along with total booking counts:

```sql
CREATE OR REPLACE VIEW monthly_performance AS
    WITH on_site_sales_summary AS (
        SELECT 
            DATE_TRUNC('month', date) AS month,
            SUM(corrected_total_net) AS total_net
        FROM on_site_sales  
        GROUP BY DATE_TRUNC('month', date)
    ),
    bookings_summary AS (
        SELECT 
            DATE_TRUNC('month', start_time) AS month,
            SUM(corrected_total_net) AS total_net,
            COUNT(*) FILTER (WHERE NOT (status = 'canceled' AND corrected_total_net <= 0)) AS total_bookings
        FROM bookings
        GROUP BY DATE_TRUNC('month', start_time)
    )
    SELECT 
        bookings_summary.month,
        bookings_summary.total_net + COALESCE(on_site_sales_summary.total_net, 0) AS total_revenue,
        bookings_summary.total_bookings
    FROM bookings_summary 
    LEFT JOIN on_site_sales_summary USING(month)
    ORDER BY month;
```

### Revenue by Location

To break revenue down by location, I first had to backfill a `location` column onto both `booking_categories` and `on_site_sales`, since on-site transactions do not record location directly. I mapped location using the escape room a transaction was tied to, and where that was not available, I fell back to device ID and known transaction amounts:

```sql
-- Infer location on booking_categories from matching bookings
ALTER TABLE booking_categories ADD COLUMN location TEXT;

UPDATE booking_categories
SET location = (
    SELECT location FROM bookings 
    WHERE bookings.escape_room = booking_categories.escape_room
      AND booking_categories.booking_category = 'Escape Room'
    LIMIT 1
);

-- Infer location on on_site_sales, falling back to device_id and amount matching
ALTER TABLE on_site_sales ADD COLUMN location TEXT;

UPDATE on_site_sales
SET location = CASE 
    WHEN item IN (SELECT on_site_sales_corresponding_item FROM booking_categories WHERE on_site_sales_corresponding_item <> 'Unsorted') 
        THEN (SELECT location FROM booking_categories WHERE booking_categories.on_site_sales_corresponding_item = on_site_sales.item LIMIT 1)
    WHEN device_id IN ('Ethan's iPhone', 'Square Terminal 4065') OR item LIKE 'Party Room%' THEN 'SoM'
    WHEN device_id = 'Square Terminal 3738' THEN 'Avalon'
    WHEN device_id IN ('Conundroom's iPad', 'Square Terminal 1554') THEN 'Downtown'
END;
```

With location filled in, I built a view that combines bookings and on-site sales revenue per location, per month:

```sql
CREATE OR REPLACE VIEW location_performance AS
    WITH on_site_sales_summary AS (
        SELECT 
            DATE_TRUNC('month', date) AS month,
            SUM(CASE WHEN location = 'Avalon' THEN corrected_total_net END) AS Avalon,
            SUM(CASE WHEN location = 'Downtown' THEN corrected_total_net END) AS Downtown,
            SUM(CASE WHEN location = 'SoM' THEN corrected_total_net END) AS SoM
        FROM on_site_sales 
        GROUP BY DATE_TRUNC('month', date)
    ),
    bookings_summary AS (
        SELECT 
            DATE_TRUNC('month', start_time) AS month,
            SUM(CASE WHEN location = 'Avalon' THEN corrected_total_net END) AS Avalon,
            SUM(CASE WHEN location = 'Downtown' THEN corrected_total_net END) AS Downtown,
            SUM(CASE WHEN location = 'SoM' THEN corrected_total_net END) AS SoM
        FROM bookings
        GROUP BY DATE_TRUNC('month', start_time)
    )
    SELECT 
        bookings_summary.month,
        bookings_summary.Avalon + COALESCE(on_site_sales_summary.Avalon, 0) AS Avalon,
        bookings_summary.Downtown + COALESCE(on_site_sales_summary.Downtown, 0) AS Downtown,
        bookings_summary.SoM + COALESCE(on_site_sales_summary.SoM, 0) AS SoM
    FROM bookings_summary
    JOIN on_site_sales_summary USING(month)
    ORDER BY month;
```
## Insights

<a href="https://public.tableau.com/app/profile/liza.snizhko/viz/ConundroomSalesDashboard2025-26/Dashboard3?publish=yes" target="_blank" rel="noopener noreferrer">
    <img width="1197" height="799" alt="image" src="https://github.com/user-attachments/assets/b26983a4-2d4c-47e3-9789-a33fe5fa0bef" />
</a>


Interactive Tableau dashboard is available here: https://public.tableau.com/app/profile/liza.snizhko/viz/ConundroomSalesDashboard2025-26/Dashboard3?publish=yes

...add more summary here...

## Summary
### Limitations Discovered:

* Walk-in booking counts cannot be separated from on-site player add-ons in the current data. On-site figures reflect revenue and participant counts only, not distinct bookings, and wherever total bookings are visualized, that number refers to online bookings only.
  
* It is not possible to identify the location where each on-site transaction was completed. The data only includes a device_id column. Some values appear frequently enough to be mapped to a location based on the escape room the transaction was for, but 17.06% are null, and 3% correspond to devices used only a handful of times.
  
* The net_sales data in the "on_site_sales" dataset cannot be treated as 100% accurate, since staff occasionally make entry errors, such as omitting tax or card fees, misclassifying items sold, or using a custom amount instead of selecting the correct item. These custom-amount entries don't correspond to any specific product, making them difficult or impossible to classify. Some transactions were manually entered or corrected via SQL.
  
* A small number of on-site transactions (27, all custom-amount entries with a missing or unrecognizable device ID, typically payments processed on an employee's personal phone) could not be reliably traced to a location and were excluded from location-level analysis.
  
* As of now, it is not possible to determine how many leads converted into inquiries by inquiry type for 2024–Q1 2025, since that data was not consolidated and was spread across Google Analytics, Zendesk, email, and disconnected phone lines.



