-- ============================================================
-- 01_data_quality_checks.sql
-- Beneficiary Service Registration demo 3
-- Source table: beneficiary_demo.kobo_raw
-- ============================================================


-- ============================================================
-- 01. TOTAL NUMBER OF RECORDS
-- ============================================================

SELECT
  COUNT(*) AS total_records
FROM `beneficiary_demo.kobo_raw`;


-- ============================================================
-- 02. MISSING REQUIRED FIELDS
-- ============================================================

SELECT
  COUNTIF(service_date IS NULL) AS missing_service_date,
  COUNTIF(project IS NULL OR TRIM(project) = '') AS missing_project,
  COUNTIF(region IS NULL OR TRIM(region) = '') AS missing_region,
  COUNTIF(community IS NULL OR TRIM(community) = '') AS missing_community,
  COUNTIF(beneficiary_id IS NULL OR TRIM(beneficiary_id) = '') AS missing_beneficiary_id,
  COUNTIF(age IS NULL) AS missing_age,
  COUNTIF(beneficiary_status IS NULL OR TRIM(beneficiary_status) = '') AS missing_beneficiary_status,
  COUNTIF(service_type IS NULL OR TRIM(service_type) = '') AS missing_service_type,
  COUNTIF(service_format IS NULL OR TRIM(service_format) = '') AS missing_service_format,
  COUNTIF(online_platform IS NULL AND service_format = 'online') AS missing_online_platform,
  COUNTIF(hours IS NULL) AS missing_hours
FROM `beneficiary_demo.kobo_raw`;


-- ============================================================
-- 03. RECORDS WITH MISSING REQUIRED FIELDS
-- ============================================================

SELECT
  _index,
  _uuid,
  service_date,
  project,
  region,
  community,
  beneficiary_id,
  age,
  beneficiary_status,
  service_type,
  service_format,
  online_platform,
  hours,
  'Missing required field' AS issue
FROM `beneficiary_demo.kobo_raw`
WHERE service_date IS NULL
   OR project IS NULL OR TRIM(project) = ''
   OR region IS NULL OR TRIM(region) = ''
   OR community IS NULL OR TRIM(community) = ''
   OR beneficiary_id IS NULL OR TRIM(beneficiary_id) = ''
   OR age IS NULL
   OR beneficiary_status IS NULL OR TRIM(beneficiary_status) = ''
   OR service_type IS NULL OR TRIM(service_type) = ''
   OR service_format IS NULL OR TRIM(service_format) = ''
   OR hours IS NULL
   OR (
        service_format = 'online'
        AND (online_platform IS NULL OR TRIM(online_platform) = '')
      );


-- ============================================================
-- 04. SERVICE DATE CANNOT BE IN THE FUTURE
-- Kobo constraint: . <= today()
-- ============================================================

SELECT
  _index,
  _uuid,
  service_date,
  'Service date is in the future' AS issue
FROM `beneficiary_demo.kobo_raw`
WHERE service_date > CURRENT_DATE();


-- ============================================================
-- 05. SERVICE DATE AFTER SUBMISSION DATE
-- Additional logical check
-- ============================================================

SELECT
  _index,
  _uuid,
  service_date,
  _submission_time,
  'Service date is later than submission date' AS issue
FROM `beneficiary_demo.kobo_raw`
WHERE service_date IS NOT NULL
  AND SAFE_CAST(_submission_time AS TIMESTAMP) IS NOT NULL
  AND service_date > DATE(SAFE_CAST(_submission_time AS TIMESTAMP));


-- ============================================================
-- 06. PROJECT - ALLOWED VALUES
-- ============================================================

SELECT
  project,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
WHERE LOWER(TRIM(project)) NOT IN (
  'mental_health_line',
  'reconnect',
  'child_protection',
  'other'
)
GROUP BY project
ORDER BY records DESC;


-- ============================================================
-- 07. PROJECT DISTRIBUTION
-- ============================================================

SELECT
  project,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY project
ORDER BY records DESC;


-- ============================================================
-- 08. REGION - ALLOWED VALUES
-- ============================================================

SELECT
  region,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
WHERE LOWER(TRIM(region)) NOT IN (
  'dnipro',
  'kharkiv',
  'other_region'
)
GROUP BY region
ORDER BY records DESC;


-- ============================================================
-- 09. REGION DISTRIBUTION
-- ============================================================

SELECT
  region,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY region
ORDER BY records DESC;


-- ============================================================
-- 10. COMMUNITY REQUIRED FOR DNIPRO / KHARKIV
-- For other_region the community question is not relevant.
-- ============================================================

SELECT
  _index,
  _uuid,
  region,
  community,
  'Community is missing for a selected oblast' AS issue
FROM `beneficiary_demo.kobo_raw`
WHERE LOWER(TRIM(region)) IN ('dnipro', 'kharkiv')
  AND (
    community IS NULL
    OR TRIM(community) = ''
  );


-- ============================================================
-- 11. COMMUNITY MUST BE EMPTY FOR other_region
-- ============================================================

SELECT
  _index,
  _uuid,
  region,
  community,
  'Community should be empty when region = other_region' AS issue
FROM `beneficiary_demo.kobo_raw`
WHERE LOWER(TRIM(region)) = 'other_region'
  AND community IS NOT NULL
  AND TRIM(community) != '';


-- ============================================================
-- 12. COMMUNITY MUST MATCH REGION PREFIX
-- kh_ = Kharkiv
-- dp_ = Dnipro
-- ============================================================

SELECT
  _index,
  _uuid,
  region,
  community,
  'Community does not match selected region' AS issue
FROM `beneficiary_demo.kobo_raw`
WHERE
      (
        LOWER(TRIM(region)) = 'kharkiv'
        AND NOT STARTS_WITH(LOWER(TRIM(community)), 'kh_')
      )
   OR (
        LOWER(TRIM(region)) = 'dnipro'
        AND NOT STARTS_WITH(LOWER(TRIM(community)), 'dp_')
      );


-- ============================================================
-- 13. COMMUNITY DISTRIBUTION
-- ============================================================

SELECT
  region,
  community,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY
  region,
  community
ORDER BY
  region,
  records DESC;


-- ============================================================
-- 14. BENEFICIARY ID FORMAT
-- Kobo constraint: ^B[0-9]{4}$
-- ============================================================

SELECT
  _index,
  _uuid,
  beneficiary_id,
  'Invalid beneficiary ID format' AS issue
FROM `beneficiary_demo.kobo_raw`
WHERE beneficiary_id IS NULL
   OR NOT REGEXP_CONTAINS(
        TRIM(beneficiary_id),
        r'^B[0-9]{4}$'
      );


-- ============================================================
-- 15. DUPLICATE BENEFICIARY IDs
-- Not automatically an error.
-- A beneficiary may receive multiple services.
-- ============================================================

SELECT
  beneficiary_id,
  COUNT(*) AS service_records
FROM `beneficiary_demo.kobo_raw`
WHERE beneficiary_id IS NOT NULL
GROUP BY beneficiary_id
HAVING COUNT(*) > 1
ORDER BY service_records DESC;


-- ============================================================
-- 16. AGE RANGE
-- Kobo constraint: . >= 0 and . <= 120
-- ============================================================

SELECT
  _index,
  _uuid,
  beneficiary_id,
  age,
  'Age outside allowed range 0-120' AS issue
FROM `beneficiary_demo.kobo_raw`
WHERE age IS NULL
   OR age < 0
   OR age > 120;


-- ============================================================
-- 17. AGE GROUP CALCULATION CHECK
--
-- Kobo calculates:
-- age < 18       -> under_18
-- age <= 25      -> 18_25
-- age <= 40      -> 26_40
-- otherwise      -> 41_plus
-- ============================================================

SELECT
  _index,
  _uuid,
  age,
  age_group,
  CASE
    WHEN age < 18 THEN 'under_18'
    WHEN age <= 25 THEN '18_25'
    WHEN age <= 40 THEN '26_40'
    ELSE '41_plus'
  END AS expected_age_group,
  'age_group does not match calculated age group' AS issue
FROM `beneficiary_demo.kobo_raw`
WHERE age_group != CASE
    WHEN age < 18 THEN 'under_18'
    WHEN age <= 25 THEN '18_25'
    WHEN age <= 40 THEN '26_40'
    ELSE '41_plus'
  END;


-- ============================================================
-- 18. AGE GROUP DISTRIBUTION
-- ============================================================

SELECT
  age_group,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY age_group
ORDER BY records DESC;


-- ============================================================
-- 19. BENEFICIARY STATUS - ALLOWED VALUES
-- ============================================================

SELECT
  beneficiary_status,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
WHERE LOWER(TRIM(beneficiary_status)) NOT IN (
  'local_resident',
  'idp',
  'returnee',
  'other'
)
GROUP BY beneficiary_status
ORDER BY records DESC;


-- ============================================================
-- 20. BENEFICIARY STATUS DISTRIBUTION
-- ============================================================

SELECT
  beneficiary_status,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY beneficiary_status
ORDER BY records DESC;


-- ============================================================
-- 21. SERVICE TYPE - ALLOWED VALUES
-- ============================================================

SELECT
  service_type,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
WHERE LOWER(TRIM(service_type)) NOT IN (
  'psychological_support',
  'legal_consultation',
  'case_management',
  'social_support',
  'information_consultation',
  'other'
)
GROUP BY service_type
ORDER BY records DESC;


-- ============================================================
-- 22. SERVICE TYPE DISTRIBUTION
-- ============================================================

SELECT
  service_type,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY service_type
ORDER BY records DESC;


-- ============================================================
-- 23. SERVICE FORMAT - ALLOWED VALUES
-- ============================================================

SELECT
  service_format,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
WHERE LOWER(TRIM(service_format)) NOT IN (
  'in_person',
  'online',
  'phone'
)
GROUP BY service_format
ORDER BY records DESC;


-- ============================================================
-- 24. SERVICE FORMAT DISTRIBUTION
-- ============================================================

SELECT
  service_format,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY service_format
ORDER BY records DESC;


-- ============================================================
-- 25. ONLINE PLATFORM MUST EXIST FOR ONLINE SERVICES
-- ============================================================

SELECT
  _index,
  _uuid,
  service_format,
  online_platform,
  'Online service has no platform' AS issue
FROM `beneficiary_demo.kobo_raw`
WHERE LOWER(TRIM(service_format)) = 'online'
  AND (
    online_platform IS NULL
    OR TRIM(online_platform) = ''
  );


-- ============================================================
-- 26. ONLINE PLATFORM MUST BE EMPTY FOR NON-ONLINE SERVICES
-- ============================================================

SELECT
  _index,
  _uuid,
  service_format,
  online_platform,
  'Online platform provided for non-online service' AS issue
FROM `beneficiary_demo.kobo_raw`
WHERE LOWER(TRIM(service_format)) IN (
    'in_person',
    'phone'
  )
  AND online_platform IS NOT NULL
  AND TRIM(online_platform) != '';


-- ============================================================
-- 27. ONLINE PLATFORM DISTRIBUTION
-- ============================================================

SELECT
  online_platform,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY online_platform
ORDER BY records DESC;


-- ============================================================
-- 28. HOURS RANGE
-- Kobo constraint: . > 0 and . <= 24
-- ============================================================

SELECT
  _index,
  _uuid,
  beneficiary_id,
  hours,
  'Hours must be greater than 0 and no more than 24' AS issue
FROM `beneficiary_demo.kobo_raw`
WHERE hours IS NULL
   OR hours <= 0
   OR hours > 24;


-- ============================================================
-- 29. HOURS DISTRIBUTION / SUMMARY
-- ============================================================

SELECT
  COUNT(*) AS records,
  MIN(hours) AS minimum_hours,
  MAX(hours) AS maximum_hours,
  AVG(hours) AS average_hours,
  SUM(hours) AS total_hours
FROM `beneficiary_demo.kobo_raw`;


-- ============================================================
-- 30. SUSPICIOUSLY HIGH SERVICE DURATION
-- WARNING ONLY - NOT NECESSARILY AN ERROR
-- ============================================================

SELECT
  _index,
  _uuid,
  beneficiary_id,
  service_date,
  service_type,
  service_format,
  hours
FROM `beneficiary_demo.kobo_raw`
WHERE hours > 8
ORDER BY hours DESC;


-- ============================================================
-- 31. DUPLICATE _ID
-- ============================================================

SELECT
  _id,
  COUNT(*) AS duplicate_count
FROM `beneficiary_demo.kobo_raw`
WHERE _id IS NOT NULL
GROUP BY _id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- ============================================================
-- 32. DUPLICATE _UUID
-- _uuid should be unique for each Kobo submission
-- ============================================================

SELECT
  _uuid,
  COUNT(*) AS duplicate_count
FROM `beneficiary_demo.kobo_raw`
WHERE _uuid IS NOT NULL
GROUP BY _uuid
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- ============================================================
-- 33. POTENTIAL DUPLICATE SERVICE
-- Same beneficiary + date + service type + format
-- WARNING, not automatically an error
-- ============================================================

SELECT
  service_date,
  beneficiary_id,
  service_type,
  service_format,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY
  service_date,
  beneficiary_id,
  service_type,
  service_format
HAVING COUNT(*) > 1
ORDER BY records DESC;


-- ============================================================
-- 34. STRONG DUPLICATE CANDIDATE
-- Same beneficiary + date + service + format + hours
-- ============================================================

SELECT
  service_date,
  beneficiary_id,
  service_type,
  service_format,
  hours,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY
  service_date,
  beneficiary_id,
  service_type,
  service_format,
  hours
HAVING COUNT(*) > 1
ORDER BY records DESC;


-- ============================================================
-- 35. INVALID UUID FORMAT
-- ============================================================

SELECT
  _index,
  _uuid,
  'Invalid UUID format' AS issue
FROM `beneficiary_demo.kobo_raw`
WHERE _uuid IS NULL
   OR NOT REGEXP_CONTAINS(
        TRIM(CAST(_uuid AS STRING)),
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
      );


-- ============================================================
-- 36. INVALID _INDEX
-- ============================================================

SELECT
  _index,
  _uuid,
  'Missing or invalid _index' AS issue
FROM `beneficiary_demo.kobo_raw`
WHERE _index IS NULL
   OR _index <= 0;


-- ============================================================
-- 37. CHECK THAT _INDEX IS UNIQUE
-- ============================================================

SELECT
  _index,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
WHERE _index IS NOT NULL
GROUP BY _index
HAVING COUNT(*) > 1
ORDER BY records DESC;


-- ============================================================
-- 38. LEADING / TRAILING SPACES
-- ============================================================

SELECT
  _index,
  _uuid,
  project,
  region,
  community,
  beneficiary_id,
  beneficiary_status,
  service_type,
  service_format,
  online_platform
FROM `beneficiary_demo.kobo_raw`
WHERE project != TRIM(project)
   OR region != TRIM(region)
   OR community != TRIM(community)
   OR beneficiary_id != TRIM(beneficiary_id)
   OR beneficiary_status != TRIM(beneficiary_status)
   OR service_type != TRIM(service_type)
   OR service_format != TRIM(service_format)
   OR online_platform != TRIM(online_platform);


-- ============================================================
-- 39. UNEXPECTED UPPERCASE / LOWERCASE VALUES
-- Shows values that differ from the standardized lowercase format.
-- ============================================================

SELECT DISTINCT
  'project' AS field_name,
  project AS value
FROM `beneficiary_demo.kobo_raw`
WHERE project != LOWER(project)

UNION ALL

SELECT DISTINCT
  'region',
  region
FROM `beneficiary_demo.kobo_raw`
WHERE region != LOWER(region)

UNION ALL

SELECT DISTINCT
  'beneficiary_status',
  beneficiary_status
FROM `beneficiary_demo.kobo_raw`
WHERE beneficiary_status != LOWER(beneficiary_status)

UNION ALL

SELECT DISTINCT
  'service_type',
  service_type
FROM `beneficiary_demo.kobo_raw`
WHERE service_type != LOWER(service_type)

UNION ALL

SELECT DISTINCT
  'service_format',
  service_format
FROM `beneficiary_demo.kobo_raw`
WHERE service_format != LOWER(service_format);


-- ============================================================
-- 40. CSV IMPORT ARTIFACT CHECK
-- There should be no semicolons or quotes inside normal values.
-- ============================================================

SELECT
  _index,
  _uuid,
  project,
  region,
  community,
  beneficiary_id,
  service_type,
  'Possible CSV import artifact' AS issue
FROM `beneficiary_demo.kobo_raw`
WHERE REGEXP_CONTAINS(CAST(project AS STRING), r'[;"]')
   OR REGEXP_CONTAINS(CAST(region AS STRING), r'[;"]')
   OR REGEXP_CONTAINS(CAST(community AS STRING), r'[;"]')
   OR REGEXP_CONTAINS(CAST(beneficiary_id AS STRING), r'[;"]')
   OR REGEXP_CONTAINS(CAST(service_type AS STRING), r'[;"]');


-- ============================================================
-- 41. SUBMISSION STATUS DISTRIBUTION
-- ============================================================

SELECT
  _status,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY _status
ORDER BY records DESC;


-- ============================================================
-- 42. VALIDATION STATUS DISTRIBUTION
-- ============================================================

SELECT
  _validation_status,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY _validation_status
ORDER BY records DESC;


-- ============================================================
-- 43. SUBMISSION DATE DISTRIBUTION
-- ============================================================

SELECT
  DATE(SAFE_CAST(_submission_time AS TIMESTAMP)) AS submission_date,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY submission_date
ORDER BY submission_date;


-- ============================================================
-- 44. SERVICE DATE DISTRIBUTION
-- ============================================================

SELECT
  service_date,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY service_date
ORDER BY service_date;


-- ============================================================
-- 45. SERVICES BY REGION AND COMMUNITY
-- ============================================================

SELECT
  region,
  community,
  COUNT(*) AS service_records,
  COUNT(DISTINCT beneficiary_id) AS unique_beneficiaries,
  SUM(hours) AS total_hours,
  AVG(hours) AS average_hours
FROM `beneficiary_demo.kobo_raw`
GROUP BY
  region,
  community
ORDER BY
  region,
  service_records DESC;


-- ============================================================
-- 46. SERVICES BY PROJECT
-- ============================================================

SELECT
  project,
  COUNT(*) AS service_records,
  COUNT(DISTINCT beneficiary_id) AS unique_beneficiaries,
  SUM(hours) AS total_hours,
  AVG(hours) AS average_hours
FROM `beneficiary_demo.kobo_raw`
GROUP BY project
ORDER BY service_records DESC;


-- ============================================================
-- 47. SERVICES BY SERVICE TYPE
-- ============================================================

SELECT
  service_type,
  COUNT(*) AS service_records,
  COUNT(DISTINCT beneficiary_id) AS unique_beneficiaries,
  SUM(hours) AS total_hours,
  AVG(hours) AS average_hours
FROM `beneficiary_demo.kobo_raw`
GROUP BY service_type
ORDER BY service_records DESC;


-- ============================================================
-- 48. SERVICES BY FORMAT
-- ============================================================

SELECT
  service_format,
  COUNT(*) AS service_records,
  COUNT(DISTINCT beneficiary_id) AS unique_beneficiaries,
  SUM(hours) AS total_hours,
  AVG(hours) AS average_hours
FROM `beneficiary_demo.kobo_raw`
GROUP BY service_format
ORDER BY service_records DESC;


-- ============================================================
-- 49. UNIQUE BENEFICIARIES VS SERVICE RECORDS
-- ============================================================

SELECT
  COUNT(*) AS total_service_records,
  COUNT(DISTINCT beneficiary_id) AS unique_beneficiaries,
  SAFE_DIVIDE(
    COUNT(*),
    COUNT(DISTINCT beneficiary_id)
  ) AS average_services_per_beneficiary
FROM `beneficiary_demo.kobo_raw`;


-- ============================================================
-- 50. BENEFICIARIES WITH MANY SERVICE RECORDS
-- WARNING ONLY
-- ============================================================

SELECT
  beneficiary_id,
  COUNT(*) AS service_records,
  SUM(hours) AS total_hours
FROM `beneficiary_demo.kobo_raw`
WHERE beneficiary_id IS NOT NULL
GROUP BY beneficiary_id
HAVING COUNT(*) > 10
ORDER BY service_records DESC;


-- ============================================================
-- 51. CROSS-CHECK: SERVICE TYPE + PROJECT
-- Useful for spotting unusual combinations.
-- This is exploratory, NOT an automatic error check.
-- ============================================================

SELECT
  project,
  service_type,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY
  project,
  service_type
ORDER BY
  project,
  records DESC;


-- ============================================================
-- 52. CROSS-CHECK: REGION + SERVICE TYPE
-- ============================================================

SELECT
  region,
  service_type,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY
  region,
  service_type
ORDER BY
  region,
  records DESC;


-- ============================================================
-- 53. CROSS-CHECK: AGE GROUP + SERVICE TYPE
-- ============================================================

SELECT
  age_group,
  service_type,
  COUNT(*) AS records
FROM `beneficiary_demo.kobo_raw`
GROUP BY
  age_group,
  service_type
ORDER BY
  age_group,
  records DESC;


-- ============================================================
-- 54. OVERALL DATA QUALITY SUMMARY
-- ============================================================

WITH checks AS (

  -- Required fields

  SELECT
    'missing_service_date' AS check_name,
    COUNTIF(service_date IS NULL) AS failed_records
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  SELECT
    'missing_project',
    COUNTIF(project IS NULL OR TRIM(project) = '')
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  SELECT
    'missing_region',
    COUNTIF(region IS NULL OR TRIM(region) = '')
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  SELECT
    'missing_community',
    COUNTIF(
      LOWER(TRIM(region)) IN ('dnipro', 'kharkiv')
      AND (community IS NULL OR TRIM(community) = '')
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  SELECT
    'missing_beneficiary_id',
    COUNTIF(beneficiary_id IS NULL OR TRIM(beneficiary_id) = '')
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  SELECT
    'missing_age',
    COUNTIF(age IS NULL)
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  SELECT
    'missing_beneficiary_status',
    COUNTIF(
      beneficiary_status IS NULL
      OR TRIM(beneficiary_status) = ''
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  SELECT
    'missing_service_type',
    COUNTIF(
      service_type IS NULL
      OR TRIM(service_type) = ''
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  SELECT
    'missing_service_format',
    COUNTIF(
      service_format IS NULL
      OR TRIM(service_format) = ''
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  SELECT
    'missing_hours',
    COUNTIF(hours IS NULL)
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  -- Date

  SELECT
    'future_service_date',
    COUNTIF(service_date > CURRENT_DATE())
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  -- Project

  SELECT
    'invalid_project',
    COUNTIF(
      LOWER(TRIM(project)) NOT IN (
        'mental_health_line',
        'reconnect',
        'child_protection',
        'other'
      )
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  -- Region

  SELECT
    'invalid_region',
    COUNTIF(
      LOWER(TRIM(region)) NOT IN (
        'dnipro',
        'kharkiv',
        'other_region'
      )
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  -- Community / region consistency

  SELECT
    'community_region_mismatch',
    COUNTIF(
         (
           LOWER(TRIM(region)) = 'kharkiv'
           AND NOT STARTS_WITH(
             LOWER(TRIM(community)),
             'kh_'
           )
         )
         OR
         (
           LOWER(TRIM(region)) = 'dnipro'
           AND NOT STARTS_WITH(
             LOWER(TRIM(community)),
             'dp_'
           )
         )
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  -- Beneficiary ID

  SELECT
    'invalid_beneficiary_id',
    COUNTIF(
      beneficiary_id IS NULL
      OR NOT REGEXP_CONTAINS(
        TRIM(beneficiary_id),
        r'^B[0-9]{4}$'
      )
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  -- Age

  SELECT
    'invalid_age',
    COUNTIF(
      age IS NULL
      OR age < 0
      OR age > 120
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  -- Age group

  SELECT
    'age_group_mismatch',
    COUNTIF(
      age_group != CASE
        WHEN age < 18 THEN 'under_18'
        WHEN age <= 25 THEN '18_25'
        WHEN age <= 40 THEN '26_40'
        ELSE '41_plus'
      END
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  -- Beneficiary status

  SELECT
    'invalid_beneficiary_status',
    COUNTIF(
      LOWER(TRIM(beneficiary_status)) NOT IN (
        'local_resident',
        'idp',
        'returnee',
        'other'
      )
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  -- Service type

  SELECT
    'invalid_service_type',
    COUNTIF(
      LOWER(TRIM(service_type)) NOT IN (
        'psychological_support',
        'legal_consultation',
        'case_management',
        'social_support',
        'information_consultation',
        'other'
      )
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  -- Service format

  SELECT
    'invalid_service_format',
    COUNTIF(
      LOWER(TRIM(service_format)) NOT IN (
        'in_person',
        'online',
        'phone'
      )
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  -- Online platform

  SELECT
    'online_without_platform',
    COUNTIF(
      LOWER(TRIM(service_format)) = 'online'
      AND (
        online_platform IS NULL
        OR TRIM(online_platform) = ''
      )
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  SELECT
    'platform_for_non_online_service',
    COUNTIF(
      LOWER(TRIM(service_format)) IN ('in_person', 'phone')
      AND online_platform IS NOT NULL
      AND TRIM(online_platform) != ''
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  -- Hours

  SELECT
    'invalid_hours',
    COUNTIF(
      hours IS NULL
      OR hours <= 0
      OR hours > 24
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  -- UUID

  SELECT
    'invalid_uuid',
    COUNTIF(
      _uuid IS NULL
      OR NOT REGEXP_CONTAINS(
        TRIM(CAST(_uuid AS STRING)),
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
      )
    )
  FROM `beneficiary_demo.kobo_raw`

  UNION ALL

  -- Duplicate UUID

  SELECT
    'duplicate_uuid',
    COUNT(*)
  FROM (
    SELECT
      _uuid
    FROM `beneficiary_demo.kobo_raw`
    WHERE _uuid IS NOT NULL
    GROUP BY _uuid
    HAVING COUNT(*) > 1
  )

  UNION ALL

  -- Duplicate ID

  SELECT
    'duplicate_id',
    COUNT(*)
  FROM (
    SELECT
      _id
    FROM `beneficiary_demo.kobo_raw`
    WHERE _id IS NOT NULL
    GROUP BY _id
    HAVING COUNT(*) > 1
  )

)

SELECT
  check_name,
  failed_records,
  CASE
    WHEN failed_records = 0 THEN 'PASS'
    ELSE 'FAIL'
  END AS status
FROM checks
ORDER BY
  CASE
    WHEN failed_records > 0 THEN 0
    ELSE 1
  END,
  failed_records DESC,
  check_name;