<!--section="fivetran-log_transformation_model"-->
# Fivetran Platform dbt Package

This dbt package transforms data from the Fivetran Platform connector into analytics-ready tables.

## Resources

- Number of materialized models¹: 26
- Connector documentation
  - [Fivetran Platform connector documentation](https://fivetran.com/docs/logs/fivetran-platform)
  - [Fivetran Platform ERD](https://fivetran.com/docs/logs/fivetran-platform#schemainformation)
- dbt package documentation
  - [GitHub repository](https://github.com/fivetran/dbt_fivetran_log)
  - [dbt Docs](https://fivetran.github.io/dbt_fivetran_log/#!/overview)
  - [DAG](https://fivetran.github.io/dbt_fivetran_log/#!/overview?g_v=1)
  - [Changelog](https://github.com/fivetran/dbt_fivetran_log/blob/main/CHANGELOG.md)
- dbt Core™ supported versions
  - `>=1.3.0, <3.0.0`

## What does this dbt package do?
This package enables you to better understand how you are spending money in Fivetran according to our [consumption-based pricing model](https://fivetran.com/docs/usage-based-pricing) and provides details about the performance and status of your Fivetran connections. It creates enriched models with metrics focused on consumption data, monthly active rows (MAR), credit consumption, connection events, schema changes, and audit logs.

### Output schema
Final output tables are generated in the following target schema:

```
<your_database>.<connector/schema_name>_fivetran_platform
```

### Final output tables

By default, this package materializes the following final tables:

| Table | Description |
| :---- | :---- |
| [fivetran_platform__connection_status](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__connection_status) | Provides a comprehensive view of each connection loading data into your destinations, enriched with detailed information about sync status, sync frequency, setup status, and connection health to monitor and troubleshoot your data pipeline performance. |
| [fivetran_platform__mar_table_history](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__mar_table_history) | Tracks a table's monthly free, paid, and total volume breakdowns, with connection and destination details to analyze your data consumption patterns and costs at the table level over time. |
| [fivetran_platform__usage_history](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__usage_history) | Summarizes each destination's monthly usage and active volume with calculated metrics for usage per million MAR and MAR per usage unit to track your Fivetran consumption costs and efficiency. Usage represents either dollar or credit amounts depending on your pricing model. Read more about the relationship between usage and MAR [here](https://www.fivetran.com/legal/service-consumption-table). |
| [fivetran_platform__connection_daily_events](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__connection_daily_events) | Captures daily operational metrics for each connection including API calls made, schema changes implemented, and record modifications processed, starting from the connection setup date to provide insights into connection activity patterns and data processing volumes. |
| [fivetran_platform__schema_changelog](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__schema_changelog) | Documents all schema changes made to your connections including table alterations, table creations, schema creations, and configuration changes with detailed metadata about each event to track data structure evolution and troubleshoot schema-related issues. |
| [fivetran_platform__audit_table](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__audit_table) | Replaces the deprecated [`_fivetran_audit` table](https://fivetran.com/docs/getting-started/system-columns-and-tables#audittables) and tracks each table receiving data during connection syncs with comprehensive timestamps for connection and table-level sync progress plus detailed counts of records inserted, replaced, updated, and deleted to monitor data processing and sync performance. |
| [fivetran_platform__audit_user_activity](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__audit_user_activity) | Records all user-triggered actions within your Fivetran account to provide a comprehensive audit trail that helps you trace user activities to specific [log events](https://fivetran.com/docs/logs#logeventlist) such as schema changes, sync frequency updates, manual syncs, connection failures, and other operational events for compliance and troubleshooting purposes. |
| [fivetran_platform__audit_trail_enriched](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__audit_trail_enriched) | Enriches each account-level audit trail event with the human-readable names of the primary and secondary resources involved (resolved for `CONNECTION`, `DESTINATION`, `ACCOUNT`, and `USER` resources) and the details of the user who performed the action, so you can audit who changed what without manually resolving resource IDs. Only available for customers on the Enterprise plan and above. |
| [fivetran_platform__transformation_run_log](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__transformation_run_log) | Surfaces each transformation run event from the Fivetran log, including start and end timestamps, formatted duration, per-step model success and failure counts, and overall transformation status to monitor and troubleshoot your transformation pipeline performance. Requires the `transformation_runs` source table. Disabled by default; set `fivetran_platform_using_transformations` to `true` to build it. |
| [fivetran_platform__connection_errors_and_warnings](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__connection_errors_and_warnings) | Consolidates error and warning events from both standard connections and Connector SDK connections into a single feed, enriched with connection details, so you can monitor and triage the severity of issues across your data pipelines. |
| [fivetran_platform__sync_metrics](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__sync_metrics) | Captures one record per completed sync, combining each sync's extract, process, load timing and volume statistics with its total duration and total records modified, enriched with connection and destination details to analyze sync performance and throughput over time. |

¹ Each Quickstart transformation job run materializes these models if all components of this data model are enabled. This count includes all staging, intermediate, and final models materialized as `view`, `table`, or `incremental`.

---

## Prerequisites

To use this dbt package, you must have the following:

- A Fivetran Platform connection syncing data into your destination.
- A **BigQuery**, **Snowflake**, **Redshift**, **Postgres**, **Databricks**, or **SQL Server** destination.

## How do I use the dbt package?
You can either add this dbt package in the Fivetran dashboard or import it into your dbt project:

- To add the package in the Fivetran dashboard, follow our [Quickstart guide](https://fivetran.com/docs/transformations/data-models/quickstart-management).
- To add the package to your dbt project, follow the setup instructions in the dbt package's [README file](https://github.com/fivetran/dbt_fivetran_log/blob/main/README.md#how-do-i-use-the-dbt-package) to use this package.

<!--section-end-->

### Install the Package
Include the following Fivetran Platform package version range in your `packages.yml`
> Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

> dbt Core >= 1.9.6 is required to run freshness tests out of the box. See other options [here](https://github.com/fivetran/dbt_fivetran_log/blob/main/CHANGELOG.md#breaking-change-for-dbt-core--196).

```yml
packages:
  - package: fivetran/fivetran_log
    version: [">=2.6.0", "<2.7.0"]
```

> Note that although the source connector is now "Fivetran Platform", the package retains the old name of "fivetran_log".

#### Databricks Dispatch Configuration
If you are using a Databricks destination with this package you will need to add the below (or a variation of the below) dispatch configuration within your `dbt_project.yml`. This is required in order for the package to accurately search for macros within the `dbt-labs/spark_utils` then the `dbt-labs/dbt_utils` packages respectively.
```yml
dispatch:
  - macro_namespace: dbt_utils
    search_order: ['spark_utils', 'dbt_utils']
```

#### Database Incremental Strategies
For models in this package that are materialized incrementally, they are configured to work with the different strategies available to each supported warehouse.

For **BigQuery** and **Databricks All Purpose Cluster runtime** destinations, we have chosen `insert_overwrite` as the default strategy, which benefits from the partitioning capability.

For **Databricks SQL Warehouse** destinations, we have chosen `merge` as the default strategy.

For **Snowflake**, **Redshift**, and **Postgres** destinations, we have chosen `delete+insert` as the default strategy.

> Regardless of strategy, we recommend that users periodically run a `--full-refresh` to ensure a high level of data quality.

### Define Database and Schema Variables
By default, this package will run using your target database and the `fivetran_log` schema. If this is not where your Fivetran Platform data is (perhaps your fivetran platform schema is `fivetran_platform`), add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    fivetran_platform_database: your_database_name # default is your target.database
    fivetran_platform_schema: your_schema_name # default is fivetran_log
```

### Disable Models for Non Existent Sources
Not every account has every source table. Quickstart automatically detects which tables are present in your schema and enables or disables the related models for you. If you run this package in your own dbt project, add the relevant variable(s) below to your root `dbt_project.yml` file:

```yml
vars:
    fivetran_platform_using_destination_membership: false # Default is true. Disables only the destination membership logic
    fivetran_platform_using_user: false # Default is true. Disables only the user logic
    fivetran_platform_using_audit_trail: true # Default is false. Set to true only if you have the audit_trail source table
    fivetran_platform_using_connector_sdk_log: true # Default is false. Set to true only if you have the connector_sdk_log source table
    fivetran_platform_using_transformations: true # Default is false for fivetran_platform__transformation_run_log. Set to true to build it
```

- `destination_membership` and `user` require Fivetran RBAC. Both are enabled by default, so disable them if you do not use RBAC.
- `audit_trail` is only available on the Enterprise plan and above. It powers the `stg_fivetran_platform__audit_trail` and `fivetran_platform__audit_trail_enriched` models, which are disabled by default.
- `connector_sdk_log` is only populated for accounts using the Fivetran Connector SDK. Enabling it includes Connector SDK events in `fivetran_platform__connection_errors_and_warnings`.
- `transformation_runs` is only populated for accounts using Fivetran Transformations. This variable resolves differently in each layer when you leave it unset:
    - `stg_fivetran_platform__transformation_runs` has no fixed default. It checks your schema for the `transformation_runs` table at runtime. If the table exists, the staging model and the `paid_model_runs`, `free_model_runs`, and `total_model_runs` fields in `fivetran_platform__usage_history` are populated. If it does not, the staging model builds empty and those fields are null.
    - `fivetran_platform__transformation_run_log` defaults to `false` and does not build. The runtime check does not apply here, so set this variable to `true` to build the model.

  Setting the variable explicitly overrides both layers. `true` requires the `transformation_runs` table to exist, and `false` disables the staging model and its downstream fields even when the table does exist.

> **Note:** We plan to remove the `does_table_exist()` runtime check in a future release so that every variable in this section has a fixed default. This affects the three variables that currently fall back to the check when unset: `fivetran_platform_using_transformations`, `fivetran_platform__usage_pricing`, and `fivetran_platform__credits_pricing`. To avoid a change in behavior when that release ships, set the variables you rely on explicitly in your root `dbt_project.yml` rather than depending on the runtime check.

#### Leveraging `CONNECTION` vs `CONNECTOR`  
In Q1 2025, the `CONNECTOR` source table was deprecated and replaced by `CONNECTION`, and `CONNECTION` is now the default source.

- For **Quickstart users**, `CONNECTOR` will automatically be used if `CONNECTION` is not yet available.
- For **dbt Core users**, if `CONNECTION` is not yet available in your connection, you can continue using `CONNECTOR` by adding the following variable to your root `dbt_project.yml` file:

```yml
vars:
    fivetran_platform_using_connection: false # default: true
```

### (Optional) Additional Configurations

#### Change the Build Schema
By default this package will build the Fivetran staging models within a schema titled (<target_schema> + `_stg_fivetran_platform`)  and the Fivetran Platform final models within your <target_schema> + `_fivetran_platform` in your target database. If this is not where you would like you Fivetran staging and final models to be written to, add the following configuration to your root `dbt_project.yml` file:

```yml
models:
  fivetran_log:
    +schema: my_new_final_models_schema # leave blank for just the target_schema
    staging:
      +schema: my_new_staging_models_schema # leave blank for just the target_schema
```

#### Change the Source Table References
If an individual source table has a different name than expected (see this projects [dbt_project.yml](https://github.com/fivetran/dbt_fivetran_log/blob/main/dbt_project.yml) variable declarations for expected names), provide the name of the table as it appears in your warehouse to the respective variable as identified below:
```yml
vars:
    fivetran_platform_<default_table_name>_identifier: your_table_name 
```

#### Limit the Lookback Window
By default, log-based models scan all available log history from the source `log` table. On large tables, this can increase query costs and/or run times. To limit the scan window, set the `fivetran_platform_log_start_date` variable to the earliest date you want to include (in `YYYY-MM-DD` format):
```yml
vars:
    fivetran_platform_log_start_date: '2024-01-01' # scan only log history on and after this date
```
This filter is applied in `stg_fivetran_platform__log`. Because it is a fixed date rather than a rolling window, the boundary does not move over time — a `--full-refresh` always reloads from the same start date, so historical data is never lost.

Incremental downstream models accumulate history over time on regular runs, and their `--full-refresh` output is bounded by the start date you set. As these models grow, you can periodically move `fivetran_platform_log_start_date` forward to keep the full-refresh scan (and the staging table) manageable. Run `dbt run --full-refresh` after setting or changing this variable to ensure all models reflect the updated window.

This affects the following models: 
  `fivetran_platform__connection_status` 
  `fivetran_platform__schema_changelog` 
  `fivetran_platform__audit_user_activity` 
  `fivetran_platform__connection_daily_events`
  `fivetran_platform__audit_table`

### (Optional) Orchestrate your models with Fivetran Transformations for dbt Core™
<details><summary>Expand for details</summary>
<br>

Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt#transformationsfordbtcore). Refer to the linked docs for more information on how to setup your project for orchestration through Fivetran.
</details>

## Does this package have dependencies?
This dbt package is dependent on the following dbt packages. These dependencies are installed by default within this package. For more information on the below packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
> **If you have any of these dependent packages in your own `packages.yml` I highly recommend you remove them to ensure there are no package version conflicts.**
```yml
packages:
    - package: fivetran/fivetran_utils
      version: [">=0.4.0", "<0.5.0"]

    - package: dbt-labs/dbt_utils
      version: [">=1.0.0", "<2.0.0"]

    - package: dbt-labs/spark_utils
      version: [">=0.3.0", "<0.4.0"]
```

<!--section="fivetran-log_maintenance"-->
## How is this package maintained and can I contribute?

### Package Maintenance
The Fivetran team maintaining this package only maintains the [latest version](https://hub.getdbt.com/fivetran/fivetran_log/latest/) of the package. We highly recommend you stay consistent with the latest version of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_fivetran_log/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

### Contributions
A small team of analytics engineers at Fivetran develops these dbt packages. However, the packages are made better by community contributions.

We highly encourage and welcome contributions to this package. Learn how to contribute to a package in dbt's [Contributing to an external dbt package article](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657).

<!--section-end-->

## Are there any resources available?
- If you encounter any questions or want to reach out for help, see the [GitHub Issue](https://github.com/fivetran/dbt_fivetran_log/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran, or would like to request a future dbt package to be developed, then feel free to fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).
