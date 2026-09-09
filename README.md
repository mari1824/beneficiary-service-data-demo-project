# beneficiary-service-data-demo-project
End-to-end data management workflow for beneficiary and service data using KoboToolbox, Google BigQuery, SQL and Looker Studio.

## Project overview

This project demonstrates how beneficiary and service data can be collected, validated, cleaned, transformed and prepared for analytical reporting in a humanitarian / social program context.

The project uses **KoboToolbox** for data collection, **Google BigQuery** for data storage and processing, **SQL** for data quality checks and transformations, and **Looker Studio** for reporting and visualization.

## Data workflow

**KoboToolbox → BigQuery → Data Quality & Validation → Data Cleaning → Analytical Tables → Looker Studio**

### BigQuery data layers

**1. `kobo_raw`**
Raw data exported from KoboToolbox.

**2. `kobo_clean`**
Cleaned and standardized dataset prepared for further analysis.

**3. `service_analytics`**
Analytical dataset at the service level, including information about services provided, projects, geography, service types, formats and duration.

**4. `beneficiary_analytics`**
Analytical dataset at the beneficiary level, including demographic characteristics, beneficiary status, service frequency and total service hours.

## Data quality and validation

SQL queries are used to perform data quality checks and identify potential issues such as:

* missing values;
* duplicate records;
* invalid or inconsistent values;
* data inconsistencies between related fields;
* values requiring review before reporting.

The validation layer is designed to ensure that only structured and quality-checked data is used for analytical reporting.

## Analytical datasets

The project separates analytical data into two main perspectives:

### Service-level analysis

Used to analyze:

* number of services provided;
* service types;
* projects;
* regions and communities;
* service formats;
* service duration;
* service activity over time.

### Beneficiary-level analysis

Used to analyze:

* unique beneficiaries;
* age and age groups;
* beneficiary status;
* number of services received;
* total service hours;
* average service duration;
* repeated service use.

## Tools

* **KoboToolbox** — data collection
* **Google BigQuery** — data storage and processing
* **SQL** — data validation, cleaning and transformation
* **Looker Studio** — reporting and visualization

## Repository structure

```text
beneficiary-service-data-management/
│
├── README.md
│
├── 01_data_quality_checks/
│   └── data_quality_checks.sql
│
├── 02_kobo_clean_creation/
│   └── kobo_clean_creation.sql
│
├── 03_service_analytics_creation/
│   └── service_analytics_creation.sql
│
└── 04_beneficiary_analytics_creation/
    └── beneficiary_analytics_creation.sql
```

## Project outcome

The final datasets are connected to a Looker Studio dashboard for interactive analysis of program activities and beneficiary profiles.

The dashboard provides an overview of key indicators and allows users to explore data by period, project, geography, service type, service format, age group and beneficiary status.

## Purpose

This project was created as a portfolio demonstration of an end-to-end approach to **beneficiary and program data management**, with a focus on data quality, structured analytical datasets and reporting needs in humanitarian and social programs.

The project uses demonstration data and does not contain real personal or sensitive beneficiary information.
