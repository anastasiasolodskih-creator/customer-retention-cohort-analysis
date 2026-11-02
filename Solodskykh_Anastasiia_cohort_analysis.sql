-- Final Project: Cohort Analysis / Retention Rate
-- Anastasiia Solodskykh


SELECT * FROM cohort_users_raw 
LIMIT 10; 

SELECT * FROM cohort_events_raw
LIMIT 10; 



-- Step 4. Clean signup dates

WITH users_prepared AS (
    SELECT
        user_id,
        signup_datetime,
        promo_signup_flag,
        REPLACE(
            REPLACE(
                SPLIT_PART(TRIM(signup_datetime), ' ', 1),
                '/',
                '-'
            ),
            '.',
            '-'
        ) AS clean_date
    FROM project.cohort_users_raw
),

users_clean AS (
    SELECT
        user_id,
        signup_datetime,
        promo_signup_flag,
        CASE
            WHEN clean_date IS NULL THEN NULL
            WHEN LENGTH(SPLIT_PART(clean_date, '-', 3)) = 2
                THEN TO_DATE(clean_date, 'DD-MM-YY')
            ELSE TO_DATE(clean_date, 'DD-MM-YYYY')
        END AS signup_date
    FROM users_prepared
)

SELECT *
FROM users_clean
LIMIT 20;


-- Step 5. Clean event dates

WITH events_prepared AS (
    SELECT
        event_id,
        user_id,
        event_datetime,
        event_type,
        revenue,
        REPLACE(
            REPLACE(
                SPLIT_PART(TRIM(event_datetime), ' ', 1),
                '/',
                '-'
            ),
            '.',
            '-'
        ) AS clean_date
    FROM project.cohort_events_raw
),

events_clean AS (
    SELECT
        event_id,
        user_id,
        event_datetime,
        event_type,
        revenue,
        CASE
            WHEN clean_date IS NULL THEN NULL
            WHEN LENGTH(SPLIT_PART(clean_date, '-', 3)) = 2
                THEN TO_DATE(clean_date, 'DD-MM-YY')
            ELSE TO_DATE(clean_date, 'DD-MM-YYYY')
        END AS event_date
    FROM events_prepared
)

SELECT *
FROM events_clean
LIMIT 20;




-- Step 6. Join users and events and calculate cohort data

WITH users_prepared AS (
    SELECT
        user_id,
        signup_datetime,
        promo_signup_flag,
        REPLACE(
            REPLACE(
                SPLIT_PART(TRIM(signup_datetime), ' ', 1),
                '/',
                '-'
            ),
            '.',
            '-'
        ) AS clean_date
    FROM project.cohort_users_raw
),

users_clean AS (
    SELECT
        user_id,
        signup_datetime,
        promo_signup_flag,
        CASE
            WHEN clean_date IS NULL THEN NULL
            WHEN LENGTH(SPLIT_PART(clean_date, '-', 3)) = 2
                THEN TO_DATE(clean_date, 'DD-MM-YY')
            ELSE TO_DATE(clean_date, 'DD-MM-YYYY')
        END AS signup_date
    FROM users_prepared
),

events_prepared AS (
    SELECT
        event_id,
        user_id,
        event_datetime,
        event_type,
        revenue,
        REPLACE(
            REPLACE(
                SPLIT_PART(TRIM(event_datetime), ' ', 1),
                '/',
                '-'
            ),
            '.',
            '-'
        ) AS clean_date
    FROM project.cohort_events_raw
),

events_clean AS (
    SELECT
        event_id,
        user_id,
        event_datetime,
        event_type,
        revenue,
        CASE
            WHEN clean_date IS NULL THEN NULL
            WHEN LENGTH(SPLIT_PART(clean_date, '-', 3)) = 2
                THEN TO_DATE(clean_date, 'DD-MM-YY')
            ELSE TO_DATE(clean_date, 'DD-MM-YYYY')
        END AS event_date
    FROM events_prepared
)

SELECT
    u.user_id,
    u.promo_signup_flag,

    CAST(DATE_TRUNC('month', u.signup_date) AS DATE) AS cohort_month,

    CAST(DATE_TRUNC('month', e.event_date) AS DATE) AS activity_month,

    (
        (EXTRACT(YEAR FROM e.event_date) - EXTRACT(YEAR FROM u.signup_date)) * 12
        +
        (EXTRACT(MONTH FROM e.event_date) - EXTRACT(MONTH FROM u.signup_date))
    ) AS month_offset

FROM users_clean u

JOIN events_clean e
    ON u.user_id = e.user_id

WHERE u.signup_date IS NOT NULL
  AND e.event_date IS NOT NULL
  AND e.event_type IS NOT NULL
  AND e.event_type <> 'test_event'

LIMIT 50;




-- Step 7. Final cohort aggregation

WITH users_prepared AS (
    SELECT
        user_id,
        signup_datetime,
        promo_signup_flag,
        REPLACE(
            REPLACE(
                SPLIT_PART(TRIM(signup_datetime), ' ', 1),
                '/',
                '-'
            ),
            '.',
            '-'
        ) AS clean_date
    FROM project.cohort_users_raw
),

users_clean AS (
    SELECT
        user_id,
        signup_datetime,
        promo_signup_flag,
        CASE
            WHEN clean_date IS NULL THEN NULL
            WHEN LENGTH(SPLIT_PART(clean_date, '-', 3)) = 2
                THEN TO_DATE(clean_date, 'DD-MM-YY')
            ELSE TO_DATE(clean_date, 'DD-MM-YYYY')
        END AS signup_date
    FROM users_prepared
),

events_prepared AS (
    SELECT
        event_id,
        user_id,
        event_datetime,
        event_type,
        revenue,
        REPLACE(
            REPLACE(
                SPLIT_PART(TRIM(event_datetime), ' ', 1),
                '/',
                '-'
            ),
            '.',
            '-'
        ) AS clean_date
    FROM project.cohort_events_raw
),

events_clean AS (
    SELECT
        event_id,
        user_id,
        event_datetime,
        event_type,
        revenue,
        CASE
            WHEN clean_date IS NULL THEN NULL
            WHEN LENGTH(SPLIT_PART(clean_date, '-', 3)) = 2
                THEN TO_DATE(clean_date, 'DD-MM-YY')
            ELSE TO_DATE(clean_date, 'DD-MM-YYYY')
        END AS event_date
    FROM events_prepared
),

joined_data AS (
    SELECT
        u.user_id,
        u.promo_signup_flag,

        CAST(
            DATE_TRUNC('month', u.signup_date)
            AS DATE
        ) AS cohort_month,

        CAST(
            DATE_TRUNC('month', e.event_date)
            AS DATE
        ) AS activity_month,

        (
            (EXTRACT(YEAR FROM e.event_date)
             - EXTRACT(YEAR FROM u.signup_date)) * 12
            +
            (EXTRACT(MONTH FROM e.event_date)
             - EXTRACT(MONTH FROM u.signup_date))
        ) AS month_offset

    FROM users_clean u

    JOIN events_clean e
        ON u.user_id = e.user_id

    WHERE u.signup_date IS NOT NULL
      AND e.event_date IS NOT NULL
      AND e.event_type IS NOT NULL
      AND e.event_type <> 'test_event'
)

SELECT
    promo_signup_flag,
    cohort_month,
    month_offset,
    COUNT(DISTINCT user_id) AS users_total

FROM joined_data

WHERE activity_month BETWEEN
      TO_DATE('01-01-2025', 'DD-MM-YYYY')
      AND TO_DATE('30-06-2025', 'DD-MM-YYYY')

GROUP BY
    promo_signup_flag,
    cohort_month,
    month_offset

ORDER BY
    promo_signup_flag,
    cohort_month,
    month_offset;