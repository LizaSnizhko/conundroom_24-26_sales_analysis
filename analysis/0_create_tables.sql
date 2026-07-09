----1---- Table for online bookings from Bookeo.com from July 1st to June 30th 2026

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

-----2---- Table for customers for all times ever

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



------3------ Table to map escape room names to categories (e.g. single escape room, special events, etc.)

CREATE TABLE booking_categories (
    escape_room TEXT,
    booking_category TEXT
);

SELECT *
FROM booking_categories

--\copy booking_categories FROM '/Users/lizasnizhko/Library/CloudStorage/OneDrive-Personal/projects/conundroom_analysis/conundroom_analysis_sql_project/data/booking_categories.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

ALTER TABLE booking_categories
ADD COLUMN on_site_sales_corresponding_item TEXT;

UPDATE booking_categories
SET on_site_sales_corresponding_item =
CASE
    WHEN escape_room = 'Alice in Wonderland' THEN 'ADD Alice player'
    WHEN escape_room = 'Crafted' THEN 'ADD Crafted player'
    WHEN escape_room = 'Cursed.' THEN 'ADD Cursed player'
    WHEN escape_room = 'Dr. Frankenstein' THEN 'ADD Frankenstein player'
    WHEN escape_room = 'Luck and Key Bar' THEN 'ADD Luck & Key Bar player'
    WHEN escape_room = 'School of Magic' THEN 'ADD School of Magic player'
    WHEN escape_room = 'Tesla''s Laboratory' THEN 'ADD Tesla Player'
    WHEN escape_room = 'The Ghost Ship' THEN 'ADD Ghost Ship player'
    WHEN escape_room = 'The Northwest Express' THEN 'ADD NW Express player'
    WHEN escape_room = 'The Vault' THEN 'ADD The Vault player'
    WHEN escape_room = 'The Wizard''s Chest' THEN 'ADD Wizard''s Chest player'
    WHEN escape_room = 'Zeppelin' THEN 'ADD Zeppelin player'
    WHEN escape_room = 'Red vs. Blue: BOMB Defuse Challenge' THEN 'Special Event'
    ELSE 'Unsorted'
END;


INSERT INTO booking_categories (escape_room, booking_category, on_site_sales_corresponding_item)
VALUES ('The Vault', 'Escape Room', 'ADD Time Travel player');

SELECT * FROM booking_categories

-------4------- Table for on-site sales from the Square payment system from July 1st to June 30th 2026

CREATE TABLE on_site_sales (
    date TIMESTAMP,
    category TEXT,
    item TEXT,
    count INTEGER,
    gross_sales NUMERIC(10,2),
    discounts NUMERIC(10,2),
    net_sales NUMERIC(10,2),
    tax NUMERIC(10,2),
    status TEXT,
    transaction_id TEXT,
    payment_id TEXT,
    device_id TEXT,
    notes TEXT,
    details TEXT,
    customer_id TEXT,
    customer_name TEXT
)

SELECT * FROM on_site_sales

-- \copy on_site_sales FROM '/Users/lizasnizhko/Library/CloudStorage/OneDrive-Personal/projects/conundroom_analysis/conundroom_analysis_sql_project/data/on_site_payments.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

------5------ Table with information about each escape room active period, as not each escape room was active or open for the entire 2 years the analysis is done for

CREATE TABLE escape_room_active_periods
(
    escape_room TEXT,
    start_date DATE,
    end_date DATE
)

-- \copy escape_room_active_periods FROM '/Users/lizasnizhko/Library/CloudStorage/OneDrive-Personal/projects/conundroom_analysis/conundroom_analysis_sql_project/data/escape_room_active_periods.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'UTF8');

SELECT * FROM  escape_room_active_periods;