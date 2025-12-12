USE stats6289_hotel_weather;

CREATE TABLE lisbon_weather (
    obs_date DATE NOT NULL,
    location VARCHAR(20) NOT NULL,
    tavg FLOAT NULL,
    tmin FLOAT NULL,
    tmax FLOAT NULL,
    prcp FLOAT NULL,
    snow FLOAT NULL,
    wdir FLOAT NULL,
    wspd FLOAT NULL,
    wpgt FLOAT NULL,
    pres FLOAT NULL,
    tsun FLOAT NULL,
    weather VARCHAR(120) NULL,
    
    PRIMARY KEY (obs_date, location)
);

CREATE TABLE algarve_weather (
    obs_date DATE NOT NULL,
    location VARCHAR(20) NOT NULL,
    tavg FLOAT NULL,
    tmin FLOAT NULL,
    tmax FLOAT NULL,
    prcp FLOAT NULL,
    snow FLOAT NULL,
    wdir FLOAT NULL,
    wspd FLOAT NULL,
    wpgt FLOAT NULL,
    pres FLOAT NULL,
    tsun FLOAT NULL,
    weather VARCHAR(120) NULL,
    
    PRIMARY KEY (obs_date, location)
);

CREATE TABLE hotel_bookings (
    booking_id INT PRIMARY KEY,

    hotel VARCHAR(50) NULL,
    location VARCHAR(20) NOT NULL,

    is_canceled INT NULL,
    lead_time INT NULL,
    arrival_date_year INT NULL,
    arrival_date_month VARCHAR(20) NULL,
    arrival_date_week_number INT NULL,
    arrival_date_day_of_month INT NULL,

    stays_in_weekend_nights INT NULL,
    stays_in_week_nights INT NULL,
    adults INT NULL,
    children FLOAT NULL,
    babies INT NULL,

    meal VARCHAR(20) NULL,
    country VARCHAR(10) NULL,
    market_segment VARCHAR(50) NULL,
    distribution_channel VARCHAR(50) NULL,

    is_repeated_guest INT NULL,
    previous_cancellations INT NULL,
    previous_bookings_not_canceled INT NULL,

    reserved_room_type VARCHAR(10) NULL,
    assigned_room_type VARCHAR(10) NULL,
    booking_changes INT NULL,
    deposit_type VARCHAR(50) NULL,
    agent INT NULL,
    company INT NULL,

    days_in_waiting_list INT NULL,
    customer_type VARCHAR(50) NULL,
    adr FLOAT NULL,
    required_car_parking_spaces INT NULL,
    total_of_special_requests INT NULL,

    reservation_status VARCHAR(50) NULL,
    reservation_status_date DATE NULL,

    original_arrival_date DATE NULL,

    INDEX idx_arrival_date (original_arrival_date),
    INDEX idx_location_date (location, original_arrival_date)
);

-- ---- to test after loading the 3 tables from .csv files------------------------------------------
SELECT obs_date FROM lisbon_weather LIMIT 5;
SELECT snow, obs_date FROM algarve_weather LIMIT 5;
SELECT booking_id, original_arrival_date FROM hotel_bookings limit 5;
SELECT * From hotel_bookings limit 6;
select * from lisbon_weather limit 6;
select * from algarve_weather limit 6;

-- #  Normalization of 2 weather datasets
-- ********* NOTE that the tables generated additionally for Normalization may not be used in further 
-- Visulization and Machine Learning processes

-- # we need to update all the NULL values in the 2 weather tables

-- To remove this dependency, we split the table into two relations: 
-- a daily observation table containing all attributes that directly depend on obs_date, 
-- and a separate Weather_Type table that stores unique weather categories. 
-- The observation table references the weather type by a foreign key (weather_code).

SET SQL_SAFE_UPDATES = 0;
UPDATE lisbon_weather
SET
    tavg = IFNULL(tavg, 0),
    tmin = IFNULL(tmin, 0),
    tmax = IFNULL(tmax, 0),
    prcp = IFNULL(prcp, 0),
    snow = IFNULL(snow, 0),
    wdir = IFNULL(wdir, 0),
    wspd = IFNULL(wspd, 0),
    wpgt = IFNULL(wpgt, 0),
    pres = IFNULL(pres, 0),
    tsun = IFNULL(tsun, 0)
WHERE obs_date IS NOT NULL;

UPDATE algarve_weather
SET
    tavg = IFNULL(tavg, 0),
    tmin = IFNULL(tmin, 0),
    tmax = IFNULL(tmax, 0),
    prcp = IFNULL(prcp, 0),
    snow = IFNULL(snow, 0),
    wdir = IFNULL(wdir, 0),
    wspd = IFNULL(wspd, 0),
    wpgt = IFNULL(wpgt, 0),
    pres = IFNULL(pres, 0),
    tsun = IFNULL(tsun, 0)
WHERE obs_date IS NOT NULL;

CREATE TABLE weather_type (
    weather_code INT AUTO_INCREMENT PRIMARY KEY,
    weather VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO weather_type (weather)
SELECT DISTINCT weather
FROM lisbon_weather
WHERE weather IS NOT NULL

UNION

SELECT DISTINCT weather
FROM algarve_weather
WHERE weather IS NOT NULL;

CREATE TABLE lisbon_weather_3nf (
    obs_date DATE PRIMARY KEY,
    tavg FLOAT NOT NULL DEFAULT 0,
    tmin FLOAT NOT NULL DEFAULT 0,
    tmax FLOAT NOT NULL DEFAULT 0,
    prcp FLOAT NOT NULL DEFAULT 0,
    snow FLOAT NOT NULL DEFAULT 0,
    wdir FLOAT NOT NULL DEFAULT 0,
    wspd FLOAT NOT NULL DEFAULT 0,
    wpgt FLOAT NOT NULL DEFAULT 0,
    pres FLOAT NOT NULL DEFAULT 0,
    tsun FLOAT NOT NULL DEFAULT 0,
    location VARCHAR(50) NOT NULL,
    weather_code INT NOT NULL,
    CONSTRAINT fk_lisbon_weather_type
        FOREIGN KEY (weather_code) REFERENCES weather_type(weather_code)
);

CREATE TABLE algarve_weather_3nf (
    obs_date DATE PRIMARY KEY,
    tavg FLOAT NOT NULL DEFAULT 0,
    tmin FLOAT NOT NULL DEFAULT 0,
    tmax FLOAT NOT NULL DEFAULT 0,
    prcp FLOAT NOT NULL DEFAULT 0,
    snow FLOAT NOT NULL DEFAULT 0,
    wdir FLOAT NOT NULL DEFAULT 0,
    wspd FLOAT NOT NULL DEFAULT 0,
    wpgt FLOAT NOT NULL DEFAULT 0,
    pres FLOAT NOT NULL DEFAULT 0,
    tsun FLOAT NOT NULL DEFAULT 0,
    location VARCHAR(50) NOT NULL,
    weather_code INT NOT NULL,
    CONSTRAINT fk_algarve_weather_type
        FOREIGN KEY (weather_code) REFERENCES weather_type(weather_code)
);

INSERT INTO lisbon_weather_3nf (
    obs_date,
    tavg, tmin, tmax,
    prcp, snow,
    wdir, wspd, wpgt,
    pres, tsun,
    location,
    weather_code
)
SELECT
    lw.obs_date,
    lw.tavg, lw.tmin, lw.tmax,
    lw.prcp, lw.snow,
    lw.wdir, lw.wspd, lw.wpgt,
    lw.pres, lw.tsun,
    lw.location,
    wt.weather_code
FROM lisbon_weather lw
JOIN weather_type wt
    ON lw.weather = wt.weather;
    
INSERT INTO algarve_weather_3nf (
    obs_date,
    tavg, tmin, tmax,
    prcp, snow,
    wdir, wspd, wpgt,
    pres, tsun,
    location,
    weather_code
)
SELECT
    aw.obs_date,
    aw.tavg, aw.tmin, aw.tmax,
    aw.prcp, aw.snow,
    aw.wdir, aw.wspd, aw.wpgt,
    aw.pres, aw.tsun,
    aw.location,
    wt.weather_code
FROM algarve_weather aw
JOIN weather_type wt
    ON aw.weather = wt.weather;    

select * from lisbon_weather_3nf;
select * from weather_type;


/*
In the original hotel_bookings table, the primary key booking_id determines original_arrival_date, 
and the arrival date components (year, month, week number, and day of month) are functionally dependent on this date. 
This induces a transitive dependency of the form booking_id → original_arrival_date → arrival_date_year/month/week/day,
which violates Third Normal Form.

To remove this transitive dependency, we decomposed the schema by introducing a separate date dimension table 
dim_arrival_date(original_arrival_date, arrival_date_year, arrival_date_month, arrival_date_week_number, 
arrival_date_day_of_month). 
The 3NF version of hotel_bookings keeps only original_arrival_date as a foreign key and no longer 
stores the derived date components. As a result, all non-key attributes in hotel_bookings now 
depend directly on the primary key, and both relations satisfy 3NF.

CREATE TABLE dim_arrival_date AS
SELECT DISTINCT
    original_arrival_date,
    arrival_date_year,
    arrival_date_month,
    arrival_date_week_number,
    arrival_date_day_of_month
FROM hotel_bookings
WHERE original_arrival_date IS NOT NULL;

-- Add primary key & NOT NULL constraints as needed
ALTER TABLE dim_arrival_date
    MODIFY original_arrival_date DATE NOT NULL,
    ADD PRIMARY KEY (original_arrival_date);

CREATE TABLE hotel_bookings_3nf AS
SELECT
    booking_id,
    hotel,
    is_canceled,
    lead_time,
    -- removed arrival_date_year
    -- removed arrival_date_month
    -- removed arrival_date_week_number
    -- removed arrival_date_day_of_month
    stays_in_weekend_nights,
    stays_in_week_nights,
    adults,
    children,
    babies,
    meal,
    country,
    market_segment,
    distribution_channel,
    is_repeated_guest,
    previous_cancellations,
    previous_bookings_not_canceled,
    reserved_room_type,
    assigned_room_type,
    booking_changes,
    deposit_type,
    agent,
    company,
    days_in_waiting_list,
    customer_type,
    adr,
    required_car_parking_spaces,
    total_of_special_requests,
    reservation_status,
    reservation_status_date,
    original_arrival_date,
    location
FROM hotel_bookings;

-- Now add primary key & foreign key constraints
ALTER TABLE hotel_bookings_3nf
    MODIFY booking_id INT NOT NULL,
    ADD PRIMARY KEY (booking_id);

-- Ensure original_arrival_date is NOT NULL if that matches your data design
ALTER TABLE hotel_bookings_3nf
    MODIFY original_arrival_date DATE NOT NULL;

ALTER TABLE hotel_bookings_3nf
    ADD CONSTRAINT fk_hb_dim_arrival_date
    FOREIGN KEY (original_arrival_date)
    REFERENCES dim_arrival_date(original_arrival_date);
    
-- Check if any bookings don't have a matching date in dim_arrival_date
-- (If this returns 0 rows, you are safe)
SELECT hb.booking_id, hb.original_arrival_date
FROM hotel_bookings_3nf hb
LEFT JOIN dim_arrival_date d
    ON hb.original_arrival_date = d.original_arrival_date
WHERE d.original_arrival_date IS NULL;    

*/


-- JOINING the two different datasets, union_weather and hotel_bookings, 
-- we then use the joined datasets to do queries and visualizations

-- before we join the 3 tables we check the unique ids for each table

SELECT MIN(obs_date), MAX(obs_date) FROM lisbon_weather;
SELECT MIN(obs_date), MAX(obs_date) FROM algarve_weather;
SELECT MIN(original_arrival_date), MAX(original_arrival_date) FROM hotel_bookings;

-- now join the two weather tables

-- since the two tables lisbon_weather and algarve_weather have same format and attributes
-- we can just simply union them

create table union_weather as 
select * from lisbon_weather
union all 
select * from algarve_weather;

-- index the location and obs_date to be used for search and as primary key
ALTER TABLE union_weather
ADD INDEX idx_location_date (location, obs_date);
-- right now in this table the primary keys are (location, obs_date)

-- now we use the union_weather to join the table hotel_bookings table to make an integrated table
CREATE TABLE hotel_weather AS
SELECT
    hb.*,
    w.tavg,
    w.tmin,
    w.tmax,
    w.prcp,
    w.snow,
    w.wdir,
    w.wspd,
    w.wpgt,
    w.pres,
    w.tsun,
    w.weather
FROM hotel_bookings hb
LEFT JOIN union_weather w
    ON hb.location = w.location
   AND hb.original_arrival_date = w.obs_date;
   
   -- test manually 
select * from hotel_weather limit 6;
SELECT COUNT(*) FROM hotel_weather;
SELECT COUNT(*) FROM hotel_bookings;   -- numbers should match

SELECT *
FROM hotel_weather
WHERE tavg IS NULL OR weather IS NULL
LIMIT 10;

-- -------------------------------------------------------------------------------------------------
-- Create view, an index, and use a constrain, you may try trigger (trigger is optional). 
-- Compare the differences between using an index and without using an index.

CREATE VIEW lisbon_booking_weather AS
SELECT
    hotel,
    location,
    original_arrival_date,
    is_canceled,
    tavg,
    prcp,
    weather
FROM hotel_weather
WHERE location = 'Lisbon';	

select * from lisbon_booking_weather limit 10;

-- we index on the merged table hotel_weather， since we haven't determined the PK for the new table
-- we define the PK and thus it will index automatically, booking_id is the index
ALTER TABLE hotel_weather
ADD PRIMARY KEY (booking_id);
SHOW INDEX FROM hotel_weather;


-- SHOW INDEX FROM hotel_weather WHERE Key_name = 'idx_loc_arrival';

-- we add another constraint to the table hotel_weather (business rule constraint):
-- the term 'is_canceled' must be 0 or 1

ALTER TABLE hotel_weather
ADD CONSTRAINT chk_is_canceled CHECK (is_canceled IN (0, 1));

-- we may also set up a trigger 
-- here we add an audit log to automatically record the booking behavior whenever cancellation occurs/changes

-- first we create another table cancel_audit
CREATE TABLE IF NOT EXISTS cancel_audit (
    id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT,
    old_status INT,
    new_status INT,
    change_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$

CREATE TRIGGER trg_cancellation_change
AFTER UPDATE ON hotel_weather
FOR EACH ROW
BEGIN
    IF OLD.is_canceled <> NEW.is_canceled THEN
        INSERT INTO cancel_audit (booking_id, old_status, new_status)
        VALUES (OLD.booking_id, OLD.is_canceled, NEW.is_canceled);
    END IF;
END$$

DELIMITER ;

-- UPDATE hotel_weather
-- SET is_canceled = 1
-- WHERE booking_id = 1000;

-- compare the differce of using index and without index
SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT booking_id) AS distinct_booking_id
FROM hotel_weather;

-- with index
EXPLAIN
SELECT *
FROM hotel_weather
WHERE booking_id = 1000;

-- without index
ALTER TABLE hotel_weather
DROP PRIMARY KEY;

EXPLAIN
SELECT *
FROM hotel_weather
WHERE booking_id = 1000;

-- add back the primary key and index
ALTER TABLE hotel_weather
ADD PRIMARY KEY (booking_id);
SHOW INDEX FROM hotel_weather;

-- -------------------------------------------------------------------------------------
-- now we design 3 queries and make table from that and we test by hand
-- 1. Find out the difference of cancellation rate between the bookings on sunny/light-rain days 
-- vs heavy-rain days in Lisbon hotels 

CREATE OR REPLACE VIEW lisbon_booking_weather AS
SELECT
    hotel, location,
    original_arrival_date, is_canceled, tavg, prcp, weather
FROM hotel_weather
WHERE location = 'Lisbon';

SELECT
    CASE 
        WHEN prcp IS NULL OR prcp = 0 THEN 'no_rain'
        WHEN prcp > 0 AND prcp <= 5 THEN 'light_rain'
        ELSE 'heavy_rain'
    END AS rain_level,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS canceled_bookings,
    ROUND(SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS cancel_rate_percent
FROM lisbon_booking_weather
GROUP BY rain_level
ORDER BY cancel_rate_percent DESC;

-- 2.Among all the ‘stormy’ weather days in Algarve (Resort Hotels), 
-- how much is the ratio of the massive hotel cancellation days? 

SELECT
    COUNT(*) AS total_stormy_windy_days,
    SUM(CASE 
            WHEN canceled_bookings * 1.0 / total_bookings >= 0.5 
            THEN 1 ELSE 0 
        END
    ) AS high_cancel_days,
    ROUND(SUM(CASE 
                WHEN canceled_bookings * 1.0 / total_bookings >= 0.5 
                THEN 1 ELSE 0 END) * 100.0/ COUNT(*), 2) AS pct_high_cancel_days
FROM (SELECT location, original_arrival_date,
        COUNT(*) AS total_bookings,
        SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS canceled_bookings
    FROM hotel_weather
    WHERE location = 'Algarve'
      AND (weather LIKE '%stormy%' OR wspd >= 20)
    GROUP BY location, original_arrival_date
) AS daily;

-- 3. Will longer waiting_list time cause higher cancellation rate? 
SELECT
    CASE
        WHEN days_in_waiting_list = 0 THEN '0 days'
        WHEN days_in_waiting_list BETWEEN 1 AND 7 THEN '1-7 days'
        WHEN days_in_waiting_list BETWEEN 8 AND 30 THEN '8-30 days'
        ELSE '30+ days'
    END AS wait_group,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS canceled_bookings,
    ROUND(
        SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS cancel_rate_percent
FROM hotel_weather
GROUP BY wait_group
ORDER BY cancel_rate_percent DESC;

-- More queries (to investigate whether weather variable as a confounder in causal relationship study) 
SELECT
    hotel,
    deposit_type,
    weather,
    COUNT(*) AS frequency
FROM hotel_weather
GROUP BY
    hotel,
    deposit_type,
    weather
ORDER BY
    hotel,
    deposit_type,
    frequency DESC;

-- -----------------------------
-- to find out the average lead time of hotel bookings for each hotel type under each weather categories

SELECT
    weather,
    hotel,
    AVG(lead_time) AS avg_lead_time
FROM hotel_weather
GROUP BY
    weather,
    hotel
ORDER BY
    weather,
    avg_lead_time DESC;






