CREATE OR REPLACE TABLE `beneficiary_demo.service_analytics` AS

SELECT
  -- =========================================================
  -- SERVICE
  -- =========================================================

  service_date,

  -- Project
  CASE project_clean
    WHEN 'mental_health_line' THEN 'Mental Health Line'
    WHEN 'reconnect' THEN 'ReCONNECT'
    WHEN 'child_protection' THEN 'Child Protection'
    WHEN 'other' THEN 'Інше'
    ELSE project_clean
  END AS project,

  -- Location
  CASE region_clean
    WHEN 'dnipro' THEN 'Дніпропетровська область'
    WHEN 'kharkiv' THEN 'Харківська область'
    WHEN 'other_region' THEN 'Інша область'
    ELSE region_clean
  END AS region,

  community_clean AS community,

  -- =========================================================
  -- BENEFICIARY
  -- =========================================================

  beneficiary_id,

  age,

  -- Age group
  CASE age_group_clean
    WHEN 'under_18' THEN 'До 18 років'
    WHEN '18_25' THEN '18–25 років'
    WHEN '26_40' THEN '26–40 років'
    WHEN '41_plus' THEN '41+ років'
    ELSE age_group_clean
  END AS age_group,

  -- Numeric sorting field for Looker Studio
  CASE age_group_clean
    WHEN 'under_18' THEN 1
    WHEN '18_25' THEN 2
    WHEN '26_40' THEN 3
    WHEN '41_plus' THEN 4
    ELSE 99
  END AS age_group_sort_order,

  -- Beneficiary status
  CASE status_clean
    WHEN 'local_resident' THEN 'Місцевий мешканець'
    WHEN 'idp' THEN 'Внутрішньо переміщена особа'
    WHEN 'returnee' THEN 'Особа, яка повернулася'
    WHEN 'other' THEN 'Інше'
    ELSE status_clean
  END AS beneficiary_status,

  -- =========================================================
  -- SERVICE INFORMATION
  -- =========================================================

  -- Service type
  CASE service_type_clean
    WHEN 'psychological_support' THEN 'Психологічна підтримка'
    WHEN 'legal_consultation' THEN 'Юридична консультація'
    WHEN 'case_management' THEN 'Кейс-менеджмент'
    WHEN 'social_support' THEN 'Соціальна підтримка'
    WHEN 'information_consultation' THEN 'Інформаційна консультація'
    WHEN 'other' THEN 'Інше'
    ELSE service_type_clean
  END AS service_type,

  -- Service format
  CASE format_clean
    WHEN 'in_person' THEN 'Очно'
    WHEN 'online' THEN 'Онлайн'
    WHEN 'phone' THEN 'Телефоном'
    ELSE format_clean
  END AS service_format,

  -- Online platform
  CASE online_platform_clean
    WHEN 'zoom' THEN 'Zoom'
    WHEN 'google_meet' THEN 'Google Meet'
    WHEN 'messenger' THEN 'Messenger'
    WHEN 'other' THEN 'Інше'
    ELSE online_platform_clean
  END AS online_platform,

  hours_clean AS hours,

  additional_comments,

  -- =========================================================
  -- TECHNICAL / DATA QUALITY FIELDS
  -- =========================================================

  record_id,

  uuid,

  submission_time AS submission_datetime,

  record_index

FROM `beneficiary_demo.kobo_clean`;