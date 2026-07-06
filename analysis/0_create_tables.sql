CREATE TABLE bookings (
    booking_number          TEXT PRIMARY KEY,
    start_time              TIMESTAMP,
    end_time                TIMESTAMP,
    first_name              TEXT,
    last_name               TEXT,
    email_address           TEXT,
    phone                   TEXT,
    participants            INTEGER,
    escape_room             TEXT,
    location                TEXT,
    product_code            TEXT,
    status                  TEXT,
    promotion               TEXT,
    coupons                 TEXT,
    adjustments             TEXT,
    total_adjustments       NUMERIC(10,2),
    total_net               NUMERIC(10,2),
    card_service_fee        NUMERIC(10,2),
    redmond_admission_tax   NUMERIC(10,2),
    total_gross             NUMERIC(10,2),
    total_paid              NUMERIC(10,2),
    total_due               NUMERIC(10,2),
    created                 TIMESTAMP,
    created_by              TEXT,
    party_room              TEXT,
    cleaning_fee            BOOLEAN,
    notes                   TEXT
);

SELECT * FROM bookings

--\copy customers FROM '/Users/lizasnizhko/Library/CloudStorage/OneDrive-Personal/projects/conundroom_analysis/conundroom_analysis_sql_project/data/combined_customers.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

CREATE TABLE customers (
    last_name         TEXT,
    first_name        TEXT,
    email_address     TEXT,
    phone             TEXT,
    location          TEXT,
    created           DATE,
    total_bookings    INTEGER,
    cancellations     INTEGER,
    no_shows          INTEGER,
    last_visit        TIMESTAMP,
    next_visit        TIMESTAMP,
    referral_source   TEXT
);

SELECT * FROM customers ORDER BY total_bookings DESC LIMIT 100 

--fixed an incorrect value
UPDATE customers
SET total_bookings = 7
WHERE email_address = 'chirasmita@222.place';

--creation of the table with escape room and its corresponding category
SELECT DISTINCT escape_room
FROM bookings
ORDER BY escape_room

CREATE TABLE booking_categories (
    escape_room TEXT,
    booking_category TEXT
);

SELECT *
FROM booking_categories

--\copy booking_categories FROM '/Users/lizasnizhko/Library/CloudStorage/OneDrive-Personal/projects/conundroom_analysis/conundroom_analysis_sql_project/data/booking_categories.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');