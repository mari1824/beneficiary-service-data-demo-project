CREATE OR REPLACE TABLE `beneficiary_demo.kobo_clean` AS

SELECT
  -- =========================================================
  -- 1. IDENTIFIERS
  -- =========================================================

  SAFE_CAST(_id AS INT64) AS record_id,

  NULLIF(TRIM(_uuid), '') AS uuid,

  SAFE_CAST(_index AS INT64) AS record_index,


  -- =========================================================
  -- 2. SERVICE DATE
  -- =========================================================

  SAFE_CAST(service_date AS DATE) AS service_date,


  -- =========================================================
  -- 3. PROJECT
  -- =========================================================

  CASE
    WHEN LOWER(TRIM(project)) = 'mental_health_line'
      THEN 'mental_health_line'

    WHEN LOWER(TRIM(project)) = 'reconnect'
      THEN 'reconnect'

    WHEN LOWER(TRIM(project)) = 'child_protection'
      THEN 'child_protection'

    WHEN LOWER(TRIM(project)) = 'other'
      THEN 'other'

    ELSE NULL
  END AS project_clean,


  -- =========================================================
  -- 4. REGION
  -- =========================================================

  CASE
    WHEN LOWER(TRIM(region)) = 'dnipro'
      THEN 'dnipro'

    WHEN LOWER(TRIM(region)) = 'kharkiv'
      THEN 'kharkiv'

    WHEN LOWER(TRIM(region)) = 'other_region'
      THEN 'other_region'

    ELSE NULL
  END AS region_clean,


  -- =========================================================
  -- 5. COMMUNITY
  -- =========================================================

  CASE
    WHEN NULLIF(TRIM(community), '') IS NULL
      THEN NULL

    ELSE LOWER(TRIM(community))
  END AS community_clean,


  -- =========================================================
  -- 6. BENEFICIARY ID
  -- =========================================================

  UPPER(TRIM(beneficiary_id)) AS beneficiary_id,


  -- =========================================================
  -- 7. AGE
  -- =========================================================

  SAFE_CAST(age AS INT64) AS age,


  -- =========================================================
  -- 8. AGE GROUP
  -- Recalculate from age instead of trusting RAW age_group
  -- =========================================================

  CASE
    WHEN SAFE_CAST(age AS INT64) < 18
      THEN 'under_18'

    WHEN SAFE_CAST(age AS INT64) BETWEEN 18 AND 25
      THEN '18_25'

    WHEN SAFE_CAST(age AS INT64) BETWEEN 26 AND 40
      THEN '26_40'

    WHEN SAFE_CAST(age AS INT64) >= 41
      THEN '41_plus'

    ELSE NULL
  END AS age_group_clean,


  -- =========================================================
  -- 9. BENEFICIARY STATUS
  -- =========================================================

  CASE
    WHEN LOWER(TRIM(beneficiary_status)) = 'local_resident'
      THEN 'local_resident'

    WHEN LOWER(TRIM(beneficiary_status)) = 'idp'
      THEN 'idp'

    WHEN LOWER(TRIM(beneficiary_status)) = 'returnee'
      THEN 'returnee'

    WHEN LOWER(TRIM(beneficiary_status)) = 'other'
      THEN 'other'

    ELSE NULL
  END AS status_clean,


  -- =========================================================
  -- 10. SERVICE TYPE
  -- =========================================================

  CASE
    WHEN LOWER(TRIM(service_type)) = 'psychological_support'
      THEN 'psychological_support'

    WHEN LOWER(TRIM(service_type)) = 'legal_consultation'
      THEN 'legal_consultation'

    WHEN LOWER(TRIM(service_type)) = 'case_management'
      THEN 'case_management'

    WHEN LOWER(TRIM(service_type)) = 'social_support'
      THEN 'social_support'

    WHEN LOWER(TRIM(service_type)) = 'information_consultation'
      THEN 'information_consultation'

    WHEN LOWER(TRIM(service_type)) = 'other'
      THEN 'other'

    ELSE NULL
  END AS service_type_clean,


  -- =========================================================
  -- 11. SERVICE FORMAT
  -- =========================================================

  CASE
    WHEN LOWER(TRIM(service_format)) = 'in_person'
      THEN 'in_person'

    WHEN LOWER(TRIM(service_format)) = 'online'
      THEN 'online'

    WHEN LOWER(TRIM(service_format)) = 'phone'
      THEN 'phone'

    ELSE NULL
  END AS format_clean,


  -- =========================================================
  -- 12. ONLINE PLATFORM
  -- Only keep platform when service format = online
  -- =========================================================

  CASE
    WHEN LOWER(TRIM(service_format)) = 'online'
      THEN NULLIF(LOWER(TRIM(online_platform)), '')

    ELSE NULL
  END AS online_platform_clean,


  -- =========================================================
  -- 13. HOURS
  -- =========================================================

  SAFE_CAST(hours AS FLOAT64) AS hours_clean,


  -- =========================================================
  -- 14. COMMENTS
  -- =========================================================

  NULLIF(TRIM(additional_comments), '') AS additional_comments,


  -- =========================================================
  -- 15. KOBO METADATA
  -- =========================================================

  SAFE_CAST(_submission_time AS TIMESTAMP) AS submission_time,

  NULLIF(TRIM(_validation_status), '') AS validation_status,

  NULLIF(TRIM(_notes), '') AS notes,

  NULLIF(TRIM(_status), '') AS submission_status,

  NULLIF(TRIM(_submitted_by), '') AS submitted_by,

  NULLIF(TRIM(__version__), '') AS kobo_version,

  NULLIF(TRIM(_tags), '') AS tags,

  NULLIF(TRIM(meta_rootUuid), '') AS meta_root_uuid


FROM `beneficiary_demo.kobo_raw`;