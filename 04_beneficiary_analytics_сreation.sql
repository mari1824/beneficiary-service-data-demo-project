CREATE OR REPLACE TABLE `beneficiary_demo.beneficiary_analytics` AS

WITH beneficiary_data AS (

  SELECT
    beneficiary_id,
    service_date,
    age,
    age_group,
    beneficiary_status,
    project,
    region,
    community,
    service_type,
    service_format,
    hours,
    submission_datetime,

    ROW_NUMBER() OVER (
      PARTITION BY beneficiary_id
      ORDER BY service_date DESC, submission_datetime DESC
    ) AS latest_record

  FROM `beneficiary_demo.service_analytics`

),

beneficiary_summary AS (

  SELECT
    beneficiary_id,

    -- =========================================================
    -- CURRENT BENEFICIARY INFORMATION
    -- =========================================================

    MAX(
      IF(latest_record = 1, age, NULL)
    ) AS age,

    MAX(
      IF(latest_record = 1, age_group, NULL)
    ) AS age_group,

    MAX(
      IF(latest_record = 1, beneficiary_status, NULL)
    ) AS beneficiary_status,

    -- =========================================================
    -- SERVICE DATES
    -- =========================================================

    MIN(service_date) AS first_service_date,

    MAX(service_date) AS last_service_date,

    -- =========================================================
    -- SERVICE VOLUME
    -- =========================================================

    COUNT(*) AS service_count,

    COUNT(DISTINCT service_date) AS service_days_count,

    SUM(hours) AS total_service_hours,

    AVG(hours) AS average_service_hours,

    -- =========================================================
    -- PROJECTS
    -- =========================================================

    COUNT(DISTINCT project) AS project_count,

    STRING_AGG(
      DISTINCT project,
      ', '
      ORDER BY project
    ) AS projects,

    -- =========================================================
    -- REGIONS
    -- =========================================================

    COUNT(DISTINCT region) AS region_count,

    STRING_AGG(
      DISTINCT region,
      ', '
      ORDER BY region
    ) AS regions,

    -- =========================================================
    -- COMMUNITIES
    -- =========================================================

    COUNT(DISTINCT community) AS community_count,

    STRING_AGG(
      DISTINCT community,
      ', '
      ORDER BY community
    ) AS communities,

    -- =========================================================
    -- SERVICE TYPES
    -- =========================================================

    COUNT(DISTINCT service_type) AS service_type_count,

    STRING_AGG(
      DISTINCT service_type,
      ', '
      ORDER BY service_type
    ) AS service_types,

    -- =========================================================
    -- SERVICE FORMAT
    -- =========================================================

    COUNTIF(service_format = 'Очно') AS offline_service_count,

    COUNTIF(service_format = 'Онлайн') AS online_service_count,

    COUNTIF(service_format = 'Телефоном') AS phone_service_count,

    -- =========================================================
    -- SERVICE FORMAT FLAGS
    -- =========================================================

    COUNTIF(service_format = 'Онлайн') > 0
      AS had_online_services,

    COUNTIF(service_format = 'Очно') > 0
      AS had_offline_services,

    COUNTIF(service_format = 'Телефоном') > 0
      AS had_phone_services

  FROM beneficiary_data

  GROUP BY beneficiary_id

)

SELECT
  *,
  
  -- =========================================================
  -- AGE GROUP SORTING
  -- =========================================================

  CASE age_group
    WHEN 'До 18 років' THEN 1
    WHEN '18–25 років' THEN 2
    WHEN '26–40 років' THEN 3
    WHEN '41+ років' THEN 4
    ELSE 99
  END AS age_group_sort_order

FROM beneficiary_summary;