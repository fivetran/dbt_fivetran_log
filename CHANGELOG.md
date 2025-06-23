# dbt_fivetran_log v2.2.0
[PR #154](https://github.com/fivetran/dbt_fivetran_log/pull/154) includes the following updates:

## Breaking Change for dbt Core < 1.9.5
> *Note: This is not relevant to Fivetran Quickstart users.*
Migrated `freshness` from a top-level source property to a source `config` in alignment with [recent updates](https://github.com/dbt-labs/dbt-core/issues/11506) from dbt Core. This will resolve the following deprecation warning that users running dbt >= 1.9.5 may have received:

```
[WARNING]: Deprecated functionality
Found `freshness` as a top-level property of `fivetran_platform` in file
`models/src_fivetran_platform.yml`. The `freshness` top-level property should be moved
into the `config` of `fivetran_platform`.
```

**IMPORTANT:** Users running dbt Core < 1.9.5 will not be able to utilize freshness tests in this release or any subsequent releases, as older versions of dbt will not recognize freshness as a source `config` and therefore not run the tests.

If you are using dbt Core < 1.9.5 and want to continue running TikTok Ads freshness tests, please elect **one** of the following options:
  1. (Recommended) Upgrade to dbt Core >= 1.9.5
  2. Do not upgrade your installed version of the `fivetran_log` package. Pin your dependency on v2.1.0 in your `packages.yml` file.
  3. Utilize a dbt [override](https://docs.getdbt.com/reference/resource-properties/overrides) to overwrite the package's `fivetran_log` source and apply freshness via the [old](https://github.com/fivetran/dbt_fivetran_log/blob/v2.1.0/models/staging/src_fivetran_platform.yml#L11-L13) top-level property route. This will require you to copy and paste the entirety of the `src_fivetran_platform.yml` [file](https://github.com/fivetran/dbt_fivetran_log/blob/v2.1.0/models/staging/src_fivetran_platform.yml#L15-L265) and add an `overrides: fivetran_log` property.

## Bug fixes
- Updated logic for identifying broken connections. Connection `sync_end` events having `log_status = 'FAILURE'`, in addition to `SEVERE` event types, are now considered broken connections. ([PR #155](https://github.com/fivetran/dbt_fivetran_log/pull/155))

## Under the Hood
- Updated the package maintainer PR template.

# dbt_fivetran_log v2.1.0
[PR #150](https://github.com/fivetran/dbt_fivetran_log/pull/150) includes the following updates:

## Dependency Changes
- Removed the dependency on [calogica/dbt_date](https://github.com/calogica/dbt-date) as it is no longer actively maintained. To maintain functionality, key date macros have been replicated within the `fivetran_date_macros` folder with minimal modifications. Only macro versions supporting the Fivetran Log supported destinations are retained, and all have been prefixed with `fivetran_` to avoid naming conflicts.
  - `date_part` -> `fivetran_date_part`
  - `day_name` -> `fivetran_day_name`
  - `day_of_month` -> `fivetran_day_of_month`

## Under the Hood
- Created consistency test on `fivetran_platform__audit_user_activity` to ensure `day_name` and `day_of_month` counts match. 

# dbt_fivetran_log v2.0.0
[PR #144](https://github.com/fivetran/dbt_fivetran_log/pull/144) includes the following updates:

## Breaking Changes - Action Required
> A `--full-refresh` is **required** after upgrading to prevent errors caused by naming and materialization changes. Additionally, downstream queries **must** be updated to reflect new model and column names.

- The materialization of all `stg_*` staging models has been updated from `table` to `view`.
  - Previously `stg_*_tmp` models were views while the non-`*_tmp` versions were tables. Now all are views to eliminate redundant data storage.

- **Source Table Transition:**
  - The `CONNECTOR` source table is deprecated and replaced by `CONNECTION`. During a brief transition period, both tables will be identical, but `CONNECTOR` will stop receiving data and be removed at a later time.
    - This change clarifies the distinction: **Connectors** facilitate the creation of **connections** between sources and destinations.
  - The `CONNECTION` table is now the default source.
    - **For Quickstart users:** The `CONNECTOR` will automatically be used if `CONNECTION` is not yet available.
    - **For dbt Core users:** Users without the `CONNECTION` source can continue using `CONNECTOR` by adding the following variable to your root `dbt_project.yml` file:
      ```yml
      vars:
          fivetran_platform_using_connection: false # default: true
      ```
    - For more details, refer to the [README](https://github.com/fivetran/dbt_fivetran_log/blob/main/README.md#leveraging-connection-vs-connector).

- New Columns:
  - As part of the `CONNECTION` updates, the following columns have been added alongside their `connector_*` equivalents:  
    - INCREMENTAL_MAR: `connection_name`  
    - LOG: `connection_id`

- Renamed Models:
  - `fivetran_platform__connector_status` → `fivetran_platform__connection_status`
  - `fivetran_platform__connector_daily_events` → `fivetran_platform__connection_daily_events`
  - `fivetran_platform__usage_mar_destination_history` → `fivetran_platform__usage_history`
  - `stg_fivetran_platform__connector` → `stg_fivetran_platform__connection`
  - `stg_fivetran_platform__connector_tmp` → `stg_fivetran_platform__connection_tmp`
> **NOTE**: Ensure any downstream queries are updated to reflect the new model names.

- Renamed Columns:
  - Renamed `connector_id` to `connection_id` and `connector_name` to `connection_name` in the following models:
    - `fivetran_platform__connection_status`
      - Also renamed `connector_health` to `connection_health`
    - `fivetran_platform__mar_table_history`
    - `fivetran_platform__connection_daily_events`
    - `fivetran_platform__audit_table`
    - `fivetran_platform__audit_user_activity`
    - `fivetran_platform__schema_changelog`
    - `stg_fivetran_platform__connection`
    - `stg_fivetran_platform__log`
       - `connector_id` to `connection_id` only
    - `stg_fivetran_platform__incremental_mar`
        - `connector_name` to `connection_name` only
> **NOTE**: Ensure any downstream queries are updated to reflect the new column names.

## Features
- Added macro `coalesce_cast` to ensure consistent data types when using `coalesce`, preventing potential errors.
- Added macro `get_connection_columns` for the new `CONNECTION` source.

## Documentation
- Updated documentation to reflect all renames and the source table transition.

## Under the Hood (Maintainers Only)
- Updated consistency and integrity tests to align with naming changes.
- Refactored seeds and `get_*_columns` macros to reflect renames.
- Added a new seed for the `CONNECTION` table.
- Updated `run_models` to test new var `fivetran_platform_using_connection`.

# dbt_fivetran_log v1.11.0
[PR #141](https://github.com/fivetran/dbt_fivetran_log/pull/141) includes the following updates:

## Schema Changes: Adding the Transformation Runs Table
- This package now accounts for the `transformation_runs` source table. Therefore, a new staging model [`stg_fivetran_platform__transformation_runs`](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.stg_fivetran_platform__transformation_runs) has been added. Note that not all customers have the `transformation_runs` source table, particularly if they are not using Fivetran Transformations. If the table doesn't exist, `stg_fivetran_platform__transformation_runs` will persist as an empty model and respective downstream fields will be null. 

- In addition, the following fields have been added to the [`fivetran_platform__usage_mar_destination_history`](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__usage_mar_destination_history) end model:
    - `paid_model_runs`
    - `free_model_runs`
    - `total_model_runs`

## Documentation Updates
- Included documentation about the `transformation_runs` source table and the aggregated `*_model_runs` fields.
- Added information about manually configuring the `fivetran_platform_using_transformations` variable in the [DECISION LOG.](https://github.com/fivetran/dbt_fivetran_log/blob/main/DECISIONLOG.md)
- Added Quickstart model counts to README. ([#145](https://github.com/fivetran/dbt_fivetran_log/pull/145))
- Corrected references to connectors and connections in the README. ([#145](https://github.com/fivetran/dbt_fivetran_log/pull/145))
- Updated dbt documentation column and table descriptions for clarity and consistency across models and sources. ([#147](https://github.com/fivetran/dbt_fivetran_log/pull/147))

## Under the Hood
- Introduced the variable `fivetran_platform_using_transformations` to control the `stg_fivetran_platform__transformation_runs` output. It is configured based on whether the `transformation_runs` table exists. For more information, refer to the [DECISION LOG.](https://github.com/fivetran/dbt_fivetran_log/blob/main/DECISIONLOG.md)
- Added the `get_transformation_runs_columns()` macro to ensure all required columns are present.
- Added `transformation_runs` seed data in `integration_tests/seeds/`.
- Added a `run_count__usage_mar_destination_history` validation test to check model run counts across staging and end model.
- (Redshift only) Updates to use limit 1 instead of limit 0 for empty tables. This ensures that Redshift will respect the package's datatype casts.

# dbt_fivetran_log v1.10.0
[PR #140](https://github.com/fivetran/dbt_fivetran_log/pull/140) includes the following updates:

## Breaking Changes
> A `--full-refresh` is recommended after upgrading to ensure historical records in incremental models are refreshed.
- Updated the `fivetran_log_json_parse` macro for Redshift to return `NULL` instead of an empty string when a JSON path is not found. This resolves errors caused by casting empty strings to integers in Redshift.
- Standardized the `message_data` field from the `LOG` source, in which JSON key names can appear in both camelCase (e.g., `{"totalQueries":5}`) and snake_case (e.g., `{"total_queries":5}`) formats, depending on the Fivetran connector version. The `fivetran_platform__audit_table` and `fivetran_platform__connector_daily_events` models now convert all key names to snake_case for consistency.
- These changes are considered breaking because the standardization of key names (e.g., `totalQueries` to `total_queries`) may impact downstream reporting by including previously ignored values.

## Under the Hood (Maintainers Only)
- Enhanced seed data for integration testing to include the different spellings and ensure compatibility with Redshift.


# dbt_fivetran_log v1.9.1
[PR #138](https://github.com/fivetran/dbt_fivetran_log/pull/138) includes the following updates:

## Features
- For Fivetran Platform Connectors created after November 2024, Fivetran has deprecated the `api_call` event in favor of `extract_summary` ([release notes](https://fivetran.com/docs/logs/changelog)).
- Accordingly, we have updated the `fivetran_platform__connector_daily_events` model to support the new `extract_summary` event while maintaining backward compatibility with the `api_call` event for connectors created before November 2024. 

## Under the Hood
- Replaced the deprecated `dbt.current_timestamp_backcompat()` function with `dbt.current_timestamp()` to ensure all timestamps are captured in UTC.
- Updated `fivetran_platform__connector_daily_events` to support running `dbt compile` prior to the initial `dbt run` on a new schema.

# dbt_fivetran_log v1.9.0
[PR #132](https://github.com/fivetran/dbt_fivetran_log/pull/132) includes the following updates:

## 🚨 Schema Changes 🚨
- Following the [July 2024 Fivetran Platform connector update](https://fivetran.com/docs/logs/fivetran-platform/changelog#july2024), the `connector_name` field has been added to the `incremental_mar` source table. As a result, the following changes have been applied:
  - A new tmp model `stg_fivetran_platform__incremental_mar_tmp` has been created. This is necessary to ensure column consistency in downstream `incremental_mar` models.
  - The `get_incremental_mar_columns()` macro has been added to ensure all required columns are present in the `stg_fivetran_platform__incremental_mar` model.
  - The `stg_fivetran_platform__incremental_mar` has been updated to reference both the aforementioned tmp model and macro to fill empty fields if any required field is not present in the source.
  - The `connector_name` field in the `stg_fivetran_platform__incremental_mar` model is now defined by: `coalesce(connector_name, connector_id)`. This ensures the data model will use the appropriate field to define the `connector_name`.

## Under the Hood
- Updated integration test seed data within `integration_tests/seeds/incremental_mar.csv` to ensure new code updates are working as expected.

# dbt_fivetran_log v1.8.0
[PR #130](https://github.com/fivetran/dbt_fivetran_log/pull/130) includes the following updates:

## 🚨 Breaking Changes 🚨
> ⚠️ Since the following changes result in the table format changing, we recommend running a `--full-refresh` after upgrading to this version to avoid possible incremental failures.
- For Databricks All-Purpose clusters, the `fivetran_platform__audit_table` model will now be materialized using the delta table format (previously parquet). 
  - Delta tables are generally more performant than parquet and are also more widely available for Databricks users. Previously, the parquet file format was causing compilation issues on customers' managed tables.

## Documentation Updates
- Updated the `sync_start` and `sync_end` field descriptions for the `fivetran_platform__audit_table` to explicitly define that these fields only represent the sync start/end times for when the connector wrote new or modified existing records to the specified table.
- Addition of integrity and consistency validation tests within integration tests for every end model.
- Removed duplicate Databricks dispatch instructions listed in the README.

## Under the Hood
- The `is_databricks_sql_warehouse` macro has been renamed to `is_incremental_compatible` and has been modified to return `true` if the Databricks runtime being used is an all-purpose cluster (previously this macro checked if a sql warehouse runtime was used) **or** if any other non-Databricks supported destination is being used.
  - This update was applied as there have been other Databricks runtimes discovered (ie. an endpoint and external runtime) which do not support the `insert_overwrite` incremental strategy used in the `fivetran_platform__audit_table` model. 
- In addition to the above, for Databricks users the `fivetran_platform__audit_table` model will now leverage the incremental strategy only if the Databricks runtime is all-purpose. Otherwise, all other Databricks runtimes will not leverage an incremental strategy.

# dbt_fivetran_log v1.7.3
[PR #126](https://github.com/fivetran/dbt_fivetran_log/pull/126) includes the following updates:

## Performance Improvements
- Updated the sequence of JSON parsing for model `fivetran_platform__audit_table` to reduce runtime. 

## Bug Fixes
- Updated model `fivetran_platform__audit_user_activity` to correct the JSON parsing used to determine column `email`. This fixes an issue introduced in v1.5.0 where `fivetran_platform__audit_user_activity` could potentially have 0 rows.

## Under the hood
- Updated logic for macro `fivetran_log_lookback` to align with logic used in similar macros in other packages. 
- Updated logic for the postgres dispatch of macro `fivetran_log_json_parse` to utilize `jsonb` instead of `json` for performance.

# dbt_fivetran_log v1.7.2
[PR #123](https://github.com/fivetran/dbt_fivetran_log/pull/123) includes the following updates:

## Bug Fixes
- Removal of the leading `/` from the `target.http_path` regex search within the `is_databricks_sql_warehouse()` macro to accurately identify SQL Warehouse Databricks destinations in Quickstart.
  - The macro above initially worked as expected in dbt core environments; however, in Quickstart implementations this data model was not working. This was due to Quickstart removing the leading `/` from the `target.http_path`. Thus resulting in the regex search to always fail. 

# dbt_fivetran_log v1.7.1
[PR #121](https://github.com/fivetran/dbt_fivetran_log/pull/121) includes the following updates:

## Bug Fixes
- Users leveraging the Databricks SQL Warehouse runtime were previously unable to run the `fivetran_platform__audit_table` model due to an incompatible incremental strategy. As such, the following updates have been made:
  - A new macro `is_databricks_sql_warehouse()` has been added to determine if a SQL Warehouse runtime for Databricks is being used. This macro will return a boolean of `true` if the runtime is determined to be SQL Warehouse and `false` if it is any other runtime or a non-Databricks destination.
  - The above macro is used in determining the incremental strategy within the `fivetran_platform__audit_table`. For Databricks SQL Warehouses, there will be **no** incremental strategy used. All other destinations and runtime strategies are not impacted with this change.
    - For the SQL Warehouse runtime, the best incremental strategy we could elect to use is the `merge` strategy. However, we do not have full confidence in the resulting data integrity of the output model when leveraging this strategy. Therefore, we opted for the model to be materialized as a non-incremental `table` for the time being.
  - The file format of the model has changed to `delta` for SQL Warehouse users. For all other destinations the `parquet` file format is still used.

## Features
- Updated README incremental model section to revise descriptions and add information for Databricks SQL Warehouse.

## Under the Hood
- Added integration testing pipeline for Databricks SQL Warehouse.
- Applied modifications to the integration testing pipeline to account for jobs being run on both Databricks All Purpose Cluster and SQL Warehouse runtimes.

# dbt_fivetran_log v1.7.0
[PR #119](https://github.com/fivetran/dbt_fivetran_log/pull/119) includes the following updates:

## 🚨 Breaking Changes 🚨: Bug Fixes
- The following fields have been deprecated (removed) as these fields proved to be problematic across warehouses due to the end size of the fields.
  - `errors_since_last_completed_sync`
  - `warnings_since_last_completed_sync`
> Note: If you found these fields to be relevant, you may still reference the error/warning messages from within the underlying `log` table.
- The `fivetran_platform_using_sync_alert_messages` variable has been removed as it is no longer necessary due to the above changes.

## Feature Updates
- The following fields have been added to display the number of error/warning messages sync last completed sync. These fields are intended to substitute the information from deprecated fields listed above.
  - `number_errors_since_last_completed_sync`
  - `number_warnings_since_last_completed_sync`

# dbt_fivetran_log v1.6.0
[PR #117](https://github.com/fivetran/dbt_fivetran_log/pull/117) includes the following updates as a result of users encountering numeric counts exceeding the limit of a standard integer. Therefore, these fields were required to be cast as `bigint` in order to avoid "integer out of range" errors:

## Breaking Changes
> ⚠️ Since the following changes result in a field changing datatype, we recommend running a `--full-refresh` after upgrading to this version to avoid possible incremental failures.
- The following fields in the `fivetran_platform__audit_table` model have been updated to be cast as `dbt.type_bigint()` (previously was `dbt.type_int()`)
  - `sum_rows_replaced_or_inserted`
  - `sum_rows_updated`
  - `sum_rows_deleted`

## Bug Fixes
- The following fields in the `fivetran_platform__connector_daily_events` model have been updated to be cast as `dbt.type_bigint()` (previously was `dbt.type_int()`)
  - `count_api_calls`
  - `count_record_modifications`
  - `count_schema_changes`

## Under the Hood
- Modified `log` seed data within the integration tests folder to ensure that large integers are being tested as part of our integration tests.

# dbt_fivetran_log v1.5.0
[PR #114](https://github.com/fivetran/dbt_fivetran_log/pull/114) includes the following updates:

## Breaking Changes
> ⚠️ Since the following changes are breaking, we recommend running a `--full-refresh` after upgrading to this version.
- For Bigquery and Databricks destinations, updated the `partition_by` config to coordinate with the filter used in the incremental logic.
- For Snowflake destinations, added a `cluster_by` config for performance. 

## Feature Updates
- Updated incremental logic for `fivetran_platform__audit_table` so that it looks back 7 days to catch any late arriving records.
- Updated JSON parsing logic in the following models to prevent run failures when incoming JSON-like strings are invalid. 
  - `fivetran_platform__audit_table`
  - `fivetran_platform__audit_user_activity`
  - `fivetran_platform__connector_daily_events`
  - `fivetran_platform__connector_status`
  - `fivetran_platform__schema_changelog`
- Updated `fivetran_platform__connector_status` to parse only a subset of the `message_data` field to improve compute.

## Under The Hood
- Added macros:
  - `fivetran_log_json_parse` to handle the updated JSON parsing.
  - `fivetran_log_lookback` for use in `fivetran_platform__audit_table`.
- Updated seeds to test handling of invalid JSON strings.

# dbt_fivetran_log v1.4.3
[PR #112](https://github.com/fivetran/dbt_fivetran_log/pull/112) includes the following updates:

## Feature Updates
- Updated logic for `connector_health` dimension in `fivetran_platform__connector_status` to show `deleted` for connectors that had been removed. Previously the connector would report the last known status before deletion, which is inaccurate based on the definition of this measure. 
- Brought in the `is_deleted` dimension (based on the `_fivetran_deleted` value) to `stg_fivetran__platform__connector` to capture connectors that are deleted in the downstream `fivetran_platform__connector_status` model.

## Under The Hood
- Renamed `get_brand_columns` macro file to `get_connector_columns` to maintain consistency with the actual macro function within the file, and the `connector` source that the macro is drawing columns from. 

# dbt_fivetran_log v1.4.2
[PR #109](https://github.com/fivetran/dbt_fivetran_log/pull/109) includes the following updates:

## Bug Fixes
- Adjusted the `stg_fivetran_platform__credits_used` and `stg_fivetran_platform__usage_cost` models to return empty tables (via a `limit 0` function, or `fetch/offset` function for SQL Server) if the respective `fivetran_platform__credits_pricing` and/or `fivetran_platform__usage_pricing` variables are disabled. This is to avoid Postgres data type errors if those tables are null. 

## Under the Hood
- Included an additional test case within the integration tests where the `fivetran_platform__credits_pricing` variable is set to false and the `fivetran_platform__usage_pricing` variable is set to true in order to effectively test this scenario.
- Updated seed files to ensure downstream models properly populate into `fivetran_platform__usage_mar_destination_history`.

# dbt_fivetran_log v1.4.1

[PR #107](https://github.com/fivetran/dbt_fivetran_log/pull/107) includes the following updates:
## Bug Fixes
- Adjusted the `fivetran_platform__audit_user_activity` model to parse the `message_data` json field to obtain the actor_email information **only** if the field contains `actor`.
  - This ensures the JSON parsing is only happening on the fields that are relevant. This will help reduce compute and avoid potential parsing errors from malformed JSON objects.

## Under the Hood
- Included auto-releaser GitHub Actions workflow to automate future releases.
- Updated the maintainer PR template to resemble the most up to date format.

# dbt_fivetran_log v1.4.0

## Feature Updates
- This release introduces compatibility with **SQL Server** 🥳  🎆  🍾 ([PR #101](https://github.com/fivetran/dbt_fivetran_log/pull/101))

## Bug Fixes
- Adjusts the uniqueness test on the recently introduced `fivetran_platform__audit_user_activity` model to test on `log_id` and `occurred_at` ([PR #102](https://github.com/fivetran/dbt_fivetran_log/pull/102)).
  - Previously, the `log_id` was erroneously considered the primary key of this model.

## Under the Hood
- Removed `order by` from the final `select` statement in each model. This was done to reduce compute costs from the models ([PR #101](https://github.com/fivetran/dbt_fivetran_log/pull/101)).
- Converted all `group by`'s to explicitly reference the names of columns we are grouping by, instead of grouping by column number. This was necessary for SQL Server compatibility, as implicit groupings are not supported ([PR #101](https://github.com/fivetran/dbt_fivetran_log/pull/101)).

# dbt_fivetran_log v1.3.0

## 🚨 Breaking Changes 🚨
- Deprecated the `transformation` and `trigger_table` source tables and any downstream transforms. These tables only housed information on Fivetran Basic SQL Transformations, which were sunset last year ([PR #96](https://github.com/fivetran/dbt_fivetran_log/pull/96)).
  - The entire `fivetran_platform__transformation_status` end model has therefore been removed.
  - As they are now obsolete, the `fivetran_platform_using_transformations` and `fivetran_platform_using_triggers` variables have been removed.

## 👶🏽 New Model Alert 👶🏽
- We have added a new model, [`fivetran_platform__audit_user_activity`](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__audit_user_activity) ([PR #98](https://github.com/fivetran/dbt_fivetran_log/pull/98)):
  - Each record represents a user-triggered action in your Fivetran instance. This model is intended for audit-trail purposes, as it can be very helpful when trying to trace a user action to a [log event](https://fivetran.com/docs/logs#logeventlist) such as a schema change, sync frequency update, manual update, broken connection, etc.
  - This model builds off of this [sample query](https://fivetran.com/docs/logs/fivetran-platform/sample-queries#audituseractionswithinconnector) from Fivetran's docs.

## 🪲 Bug Fixes 🪲
- Tightened incremental logic in `fivetran_platform__audit_table`, which was seeing duplicates on incremental runs ([PR #97](https://github.com/fivetran/dbt_fivetran_log/pull/97)).
  - If you are seeing uniqueness test failures on the `unique_table_sync_key` field, please run a full refresh before upgrading to this version of the package.

## 🛠 Under the Hood 🛠
- Added a dependency on the `dbt_date` package ([PR #98](https://github.com/fivetran/dbt_fivetran_log/pull/98)):
```yml
- package: calogica/dbt_date
  version: [">=0.9.0", "<1.0.0"]
```

# dbt_fivetran_log v1.2.0

[PR #92](https://github.com/fivetran/dbt_fivetran_log/pull/92) includes the following updates:
## Bug Fixes
- The `unique_table_sync_key` surrogate key which is created within the `fivetran_platform__audit_table` has been updated to also be comprised of the `schema_name` in addition to the `connector_id`, `destination_id`, `table_name`, `write_to_table_start` fields. This update will also ensure the uniqueness test on this record is accurately testing the true grain of the model.
  - 🚨 Please be aware that as the `fivetran_platform__audit_table` model is an incremental model a `--full-refresh` will be needed following the package upgrade in order for this change to properly be applied to all records in the end model. 🚨

## Contributors
- [@JustMaris](https://github.com/JustMaris) ([#92](https://github.com/fivetran/dbt_fivetran_log/pull/92))

# dbt_fivetran_log v1.1.0

[PR #87](https://github.com/fivetran/dbt_fivetran_log/pull/87) includes the following updates:
## 🚨 Feature Updates (Breaking Change) 🚨 
The below change was made to an incremental model. As such, a `dbt run --full-refresh` will be required following an upgrade to capture the new column.
-  Added `schema_name` to the `fivetran_platform__audit_table` end model. This schema name field is captured from the `message_data` JSON within the `log` source table. In cases where the `schema_name` is not provided, a coalesce was added to replicate the `connector_name` as the `schema_name`.
> **Note**: This may change the row count of your `fivetran_platform__audit_table` model. However, this new row count is more correct, as it more accurately captures records from [database connectors](https://fivetran.com/docs/databases), which can write to multiple schemas.

## Documentation Updates
- Fixed links in the README models section to properly redirect to the dbt hosted docs for the relevant models.

# dbt_fivetran_log v1.0.1
## Bugfix:
- Update staging models CTE names to current standard used in our other packages (the base, fields, final approach) to avoid potential circular references ([PR #85](https://github.com/fivetran/dbt_fivetran_log/pull/85))

# dbt_fivetran_log v1.0.0

![image](https://user-images.githubusercontent.com/65564846/236957050-a5ee484d-9b05-4207-a34a-22c3b8e5a0e6.png)

The Fivetran Log connector has been renamed to the "Fivetran Platform" connector. To align with this name change, this package is _largely_ being renamed from `fivetran_log` to `fivetran_platform`. This is a very breaking change! 🚨 🚨 🚨 🚨

**Bottom Line**: What you need to update and/or know:
- If you are setting any variables for this package in your `dbt_project.yml`, update the name of the prefix of the variable(s) from `fivetran_log_*` to `fivetran_platform_*`. The default _values_ for variables have not changed.
- Similarly, any references to package models will need to be updated. The prefix of package models has been updated from `fivetran_log__*` to `fivetran_platform__*`.
- If you are [overriding](https://docs.getdbt.com/reference/resource-properties/overrides) the `fivetran_log` source, you will need to update the `overrides` property to match the new `source` name (`fivetran_platform`).
- Run a full refresh, as we have updated the incremental strategies across warehouses.
- The default [build schema](https://github.com/fivetran/dbt_fivetran_log#change-the-build-schema) suffixes have been changed from `_stg_fivetran_log` and `_fivetran_log` to `_stg_fivetran_platform` and `_fivetran_platform` respectively. We recommend dropping the old schemas.

**Note**: Things that are NOT changing in the package:
- The name of the Github repository will not be changed. It will remain `dbt_fivetran_log` 
- The package's project name will remain `fivetran_log`. You will **not** need to update your `packages.yml` reference.
- The default source schema will remain `fivetran_log`. The _name_ of the source schema variable has changed though (`fivetran_log_schema` -> `fivetran_platform_schema`).

**See details below!**

[PR #81](https://github.com/fivetran/dbt_fivetran_log/pull/81) introduced the following changes (some unrelated to the connector name change):

##  🚨 Breaking Changes 🚨
- Updated the prefixes of each model from `fivetran_log_*` or `stg_fivetran_log_*` to `fivetran_platform_*` and `stg_fivetran_platform_*`, respectively.

| **Original model name**  | **New model name** |
| ----------------------- | ----------------------- |
| fivetran_log__audit_table      | fivetran_platform__audit_table       |
| fivetran_log__connector_daily_events      | fivetran_platform__connector_daily_events       |
| fivetran_log__connector_status      | fivetran_platform__connector_status       |
| fivetran_log__mar_table_history      | fivetran_platform__mar_table_history       |
| fivetran_log__schema_changelog      | fivetran_platform__schema_changelog       |
| fivetran_log__transformation_status      | fivetran_platform__transformation_status       |
| fivetran_log__usage_mar_destination_history      | fivetran_platform__usage_mar_destination_history       |
| stg_fivetran_log__account      | stg_fivetran_platform__account       |
| stg_fivetran_log__connector      | stg_fivetran_platform__connector     |
| stg_fivetran_log__credits_used      | stg_fivetran_platform__credits_used       |
| stg_fivetran_log__destination_membership      | stg_fivetran_platform__destination_membership       |
| stg_fivetran_log__destination      | stg_fivetran_platform__destination       |
| stg_fivetran_log__incremental_mar      | stg_fivetran_platform__incremental_mar       |
| stg_fivetran_log__log      | stg_fivetran_platform__log       |
| stg_fivetran_log__transformation      | stg_fivetran_platform__transformation       |
| stg_fivetran_log__trigger_table      | stg_fivetran_platform__trigger_table       |
| stg_fivetran_log__usage_cost      | stg_fivetran_platform__usage_cost       |
| stg_fivetran_log__user      | stg_fivetran_platform__user       |

- Updated the prefix of **all** package variables from `fivetran_log_*` to `fivetran_platform_*`. 

| **Original variable name**   | **New variable name** | **Default value (consistent)**  |
| ----------------------- | ----------------------- | ----------------------- |
| fivetran_log_schema      | fivetran_platform_schema       | `fivetran_log` | 
| fivetran_log_database      | fivetran_platform_database       | `target.database` | 
| fivetran_log__usage_pricing      | fivetran_platform__usage_pricing       |  Dynamically checks the source at runtime to set as either `true` or `false`. May be overridden using this variable if desired. | 
| fivetran_log__credits_pricing      | fivetran_platform__credits_pricing       |  Dynamically checks the source at runtime to set as either `true` or `false`. May be overridden using this variable if desired | 
| fivetran_log_using_sync_alert_messages | fivetran_platform_using_sync_alert_messages | `True` | 
| fivetran_log_using_transformations      | fivetran_platform_using_transformations       | `True` | 
| fivetran_log_using_triggers      | fivetran_platform_using_triggers       | `True` | 
| fivetran_log_using_destination_membership      | fivetran_platform_using_destination_membership       | `True` | 
| fivetran_log_using_user      | fivetran_platform_using_user       | `True` | 
| fivetran_log_[default_table_name]\_identifier  |  fivetran_platform_[default_table_name]_identifier | Default table name (ie `'connector'` for `fivetran_platform_connector_identifier`) | 

- Updated the default [build schema](https://github.com/fivetran/dbt_fivetran_log#change-the-build-schema) suffixes of package models from `_stg_fivetran_log` and `_fivetran_log` to `_stg_fivetran_platform` and `_fivetran_platform` respectively.
> We recommend dropping the old schemas to eradicate the stale pre-name-change models from your destintation. 
- Updated the name of the package's [source](models/staging/src_fivetran.yml) from `fivetran_log` to `fivetran_platform`.
- Updated the name of the packages' schema files:
  - `src_fivetran_log.yml` -> `src_fivetran_platform.yml`
  - `stg_fivetran_log.yml` -> `stg_fivetran_platform.yml`
  - `fivetran_log.yml` -> `fivetran_platform.yml`
- Updated the freshness tests on the `fivetran_platform` source to be less stringent and more realistic. The following source tables have had their default fresness tests removed, as they will not necessarily update frequently:
  - `connector`
  - `account`
  - `destination`
  - `destination_membership`
  - `user`
- Updated the incremental strategy of the audit table [model](models/fivetran_platform__audit_table.sql) for BigQuery and Databricks users from `merge` to the more consistent `insert_overwrite` method. We have also updated the `file_format` to `parquet` and added a partition on a new `sync_start_day` field for Databricks. This field is merely a truncated version of `sync_start`.
  - Run a full refresh to capture these new changes. We recommend running a full refresh every so often regardless. See README for more details.
- The `account_membership` source table (and any of its transformations) has been deprecated. Fivetran deprecated this table from the connector in [June 2023](https://fivetran.com/docs/logs/fivetran-log/changelog#june2023).

### Considerations
- ⚠️ If you are [overriding](https://docs.getdbt.com/reference/resource-properties/overrides) the `fivetran_log` source, you will need to update the `overrides` property to match the new `source` name (`fivetran_platform`).

## Under the Hood
- Added documentation for fields missing yml entries. 
- Incorporated the new `fivetran_utils.drop_schemas_automation` macro into the end of each Buildkite integration test job ([PR #80](https://github.com/fivetran/dbt_fivetran_log/pull/80)).
- Updated the pull request templates ([PR #80](https://github.com/fivetran/dbt_fivetran_log/pull/80)).

# dbt_fivetran_log v0.7.4
[PR #79](https://github.com/fivetran/dbt_fivetran_log/pull/79) includes the following updates:

## Enhancements
- The `sync_id` field from the source `log` table is added to the `stg_fivetran_log__log` model for ease of grouping events by the sync that they are associated with.

## Under the Hood
- Added the `get_log_columns` macro and included the fill staging cte's within the `stg_fivetran_log__log` model to ensure the model succeeds regardless of a user not having all the required fields.

## Documentation Updates
- The `sync_id` field is added to the documentation in the `fivetran_log.yml` file.

## Contributors
- [@camcyr-at-brzwy](https://github.com/camcyr-at-brzwy) ([#79](https://github.com/fivetran/dbt_fivetran_log/pull/79))

# dbt_fivetran_log v0.7.3
PR [#77](https://github.com/fivetran/dbt_fivetran_log/pull/77) includes the following updates:
## Bug Fixes
- The logic within the `does_table_exist` macro would run the source_relation check across **all** nodes. This opened dbt compile to erroneous failures in other (non fivetran_log) sources. This macro logic has been updated to only check the source_relation for the specific source in question.
- Adjusted the enabled variable used within the `stg_fivetran_log__credits_used` model to the more appropriate `fivetran_log__credits_pricing` name as opposed to `fivetran_log__usage_pricing`. This ensures a user may override the respective model enablement in isolation of each other.

## Documentation Updates
- Added a DECISIONLOG to support the logic behind the `fivetran_log__usage_pricing` and `fivetran_log__credits_pricing` variable behaviors within the package.

## Contributors
- [@dimoschi](https://github.com/dimoschi) for sharing the code applied within [#77](https://github.com/fivetran/dbt_fivetran_log/pull/77)
# dbt_fivetran_log v0.7.2
## Bug Fixes
- Fixed duplicated rows in `fivetran_log__mar_table_history` and set the model back to a monthly granularity for each source, destination, and table. ([#74](https://github.com/fivetran/dbt_fivetran_log/pull/74))

## Under the Hood
- Adjusted the uniqueness test within the `fivetran_log__mar_table_history` to also include the `schema_name` as the same table may exist in multiple schemas within a connector/destination. ([#74](https://github.com/fivetran/dbt_fivetran_log/pull/74))

## Contributors
- [@simon-stepper](https://github.com/simon-stepper) ([#73](https://github.com/fivetran/dbt_fivetran_log/issues/73))

# dbt_fivetran_log v0.7.1
## Bug Fixes
- Modified the logic within the `fivetran_log__mar_table_history` model to no longer filter out previous historical MAR records. Previously, these fields were filtered out as the `active_volume` source (since deprecated and replaced with `incremental_mar`) produced a cumulative daily MAR total. However, the `incremental_mar` source is not cumulative and will need to include all historical records. ([#72](https://github.com/fivetran/dbt_fivetran_log/pull/72))

## Under the Hood
- Added coalesce statements to the `paid_monthly_active_rows` and `free_monthly_active_rows` fields within the [fivetran_log__mar_table_history](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_log__mar_table_history) model to coalesce to 0. ([#72](https://github.com/fivetran/dbt_fivetran_log/pull/72))

## Contributors
- [@pkanter](https://github.com/pkanter) ([#63](https://github.com/fivetran/dbt_fivetran_log/issues/63))

# dbt_fivetran_log v0.7.0

## 🚨 Breaking Changes 🚨:
[PR #64](https://github.com/fivetran/dbt_fivetran_log/pull/64) includes the following breaking changes:
- Dispatch update for dbt-utils to dbt-core cross-db macros migration. Specifically `{{ dbt_utils.<macro> }}` have been updated to `{{ dbt.<macro> }}` for the below macros:
    - `any_value`
    - `bool_or`
    - `cast_bool_to_text`
    - `concat`
    - `date_trunc`
    - `dateadd`
    - `datediff`
    - `escape_single_quotes`
    - `except`
    - `hash`
    - `intersect`
    - `last_day`
    - `length`
    - `listagg`
    - `position`
    - `replace`
    - `right`
    - `safe_cast`
    - `split_part`
    - `string_literal`
    - `type_bigint`
    - `type_float`
    - `type_int`
    - `type_numeric`
    - `type_string`
    - `type_timestamp`
    - `array_append`
    - `array_concat`
    - `array_construct`
- For `current_timestamp` and `current_timestamp_in_utc` macros, the dispatch AND the macro names have been updated to the below, respectively:
    - `dbt.current_timestamp_backcompat`
    - `dbt.current_timestamp_in_utc_backcompat`
- `dbt_utils.surrogate_key` has also been updated to `dbt_utils.generate_surrogate_key`. Since the method for creating surrogate keys differ, we suggest all users do a `full-refresh` for the most accurate data. For more information, please refer to dbt-utils [release notes](https://github.com/dbt-labs/dbt-utils/releases) for this update.
- `packages.yml` has been updated to reflect new default `fivetran/fivetran_utils` version, previously `[">=0.3.0", "<0.4.0"]` now `[">=0.4.0", "<0.5.0"]`.

[PR #68](https://github.com/fivetran/dbt_fivetran_log/pull/68) includes the following breaking changes:
- The `active_volume` source (and accompanying `stg_fivetran_log__active_volume` model) has been deprecated from the Fivetran Log connector. In its place, the `incremental_mar` table (and accompanying `stg_fivetran_log__incremental_mar` model) has been added. This new source has been swapped within the package to reference the new source table.
  - This new source table has enriched data behind the paid and free MAR across Fivetran connectors within your destinations.
- Removed the `monthly_active_rows` field from the `fivetran_log__mar_table_history` and `fivetran_log__usage_mar_destination_history` models. In it's place the following fields have been added:
  - `free_mothly_active_rows`: Detailing the total free MAR
  - `paid_mothly_active_rows`: Detailing the total paid MAR
  - `total_mothly_active_rows`: Detailing the total free and paid MAR

# dbt_fivetran_log v0.6.4
## Fixes
- Added second qualifying join clause to `fivetran_log__usage_mar_destination_history` in the `usage` cte. This join was failing this test to ensure each `destination_id` has a single `measured_month` :

```
      - dbt_utils.unique_combination_of_columns:
          combination_of_columns:
            - destination_id
            - measured_month
```

## Under the Hood
- BuildKite testing has been added. ([#70](https://github.com/fivetran/dbt_fivetran_log/pull/70))

## Contributors
- [@lord-skinner](https://github.com/lord-skinner) ([#67](https://github.com/fivetran/dbt_fivetran_log/pull/67))

# dbt_fivetran_log v0.6.3
## Fixes
- Modified the argument used for the identifier in the get_relation macro used in the does_table_exist macro from name to identifier. This avoids issues on snowflake where the name of a table defined in a source yaml may be in lowercase while in snowflake it is uppercased.
## Contributors
- [@ggmblr](https://github.com/ggmblr) ([#60](https://github.com/fivetran/dbt_fivetran_log/pull/60))

# dbt_fivetran_log v0.6.2
## Fixes
- Extend model disablement with `config: is_enabled` setting in sources to avoid running source freshness when a model is disabled. ([#58](https://github.com/fivetran/dbt_fivetran_log/pull/58))
## Contributors
- [@epapineau](https://github.com/epapineau) ([#58](https://github.com/fivetran/dbt_fivetran_log/pull/58))

# dbt_fivetran_log v0.6.1
## Fixes
- Added the option to disable the `user`, `account_membership`, and `destination_membership` models that may not be available depending on your Fivetran setup. In your `dbt_project.yml` you can now change these flags to disable parts of the package. Use the below to configure your project. ([#52](https://github.com/fivetran/dbt_fivetran_log/pull/52)) and ([#55](https://github.com/fivetran/dbt_fivetran_log/pull/55))

  ```yml
  fivetran_log_using_account_membership: false # Disables account membership models
  fivetran_log_using_destination_membership: false # Disables account membership models
  fivetran_log_using_user: false # Disables account membership models
  ```

## Contributors
- [@cmcau](https://github.com/cmcau) ([#52](https://github.com/fivetran/dbt_fivetran_log/pull/52))
# dbt_fivetran_log v0.6.0
## 🚨 Breaking Changes 🚨
- This release includes updates to the `fivetran_log__credit_mar_destination_history` and `stg_fivetran_log__credits_used` models to account for the new Fivetran pricing model. These changes include: ([#50](https://github.com/fivetran/dbt_fivetran_log/pull/50))
  - `stg_fivetran_log__credits_used`
    - The field `credits_consumed` has been renamed to `credits_spent`
  - `fivetran_log__credit_mar_destination_history`
    - The model has been renamed to `fivetran_log__usage_mar_destination_history`
    - The field `credits_per_million_mar` has been renamed to `credits_spent_per_million_mar`
    - The field `mar_per_credit` has been renamed to `mar_per_credit_spent`

## 🎉 Features 🎉
- README documentation updates for easier experience leveraging the dbt package.
- Added `fivetran_log_[source_table_name]_identifier` variables to allow for easier flexibility of the package to refer to source tables with different names.
- This package now accounts for the new Fivetran pricing model. In particular, the new model accounts for the amount of dollars spend vs credits spent. Therefore, a new staging model `stg_fivetran_log__usage_cost` has been added. ([#50](https://github.com/fivetran/dbt_fivetran_log/pull/50))
  - This model relies on the `usage_cost` source table. If you do not have this source table it means you are not on the new pricing model yet. Please note, the dbt package will still generate this staging model. However, the model will be comprised of all `null` records.
- In addition to the new staging model, two new fields have been added to the `fivetran_log__usage_mar_destination_history` model. These fields mirror the credits spent fields, but account for the amount of dollars spent instead of credits. ([#50](https://github.com/fivetran/dbt_fivetran_log/pull/50))
  - `amount_spent_per_million_mar`
  - `mar_per_amount_spent`

## Under the Hood
- Introduces a new macro `does_table_exist` to be leveraged in the new pricing model updates. This macro will check the sources defined and provide either `true` or `false` if the table does or does not exist in the schema. ([#50](https://github.com/fivetran/dbt_fivetran_log/pull/50))

# dbt_fivetran_log v0.5.4
## Fixes
- The unique combination of columns test within the `fivetran_log__schema_changelog` model has been updated to also check the `message_data` field. This is needed as schema changelog events may now sync at the same time. ([#51](https://github.com/fivetran/dbt_fivetran_log/pull/51))
- The `fivetran_log__connector_status` model has been adjusted to filter out all logs that contain a `transformation_id`. Transformation logs are not always synced as a JSON object and thus the package may encounter errors on Snowflake warehouses when parsing non-JSON fields. Since transformation records are not used in this end model, they have been filtered out. ([#51](https://github.com/fivetran/dbt_fivetran_log/pull/51))

# dbt_fivetran_log v0.5.3
## Fixes
- Per the [Fivetran Log December 2021 Release Notes](https://fivetran.com/docs/logs/changelog#december2021) every sync results in a final `sync_end` event. In the previous version of this package, a successful sync was identified via a `sync_end` event while anything else was a version of broken. Since all syncs result in a `sync_end` event now, the package has been updated to account for this change within the connector.
- To account for the above fix, a new field (`last_successful_sync_completed_at`) was added to the `fivetran_log__connector_status` model. This field captures the last successful sync for the connector.
# dbt_fivetran_log v0.5.2
## Fixes
- The `fivetran_log__connector_status` model uses a date function off of `created_at` from the `stg_fivetran_log__log` model. This fails on certain redshift destinations as the timestamp is synced as `timestamptz`. Therefore, the field within the staging model is cast using `dbt_utils.type_timestamp` to appropriately cast the field for downstream functions. Further, to future proof, timestamps were cast within the following staging models: `account`, `account_membership`, `active_volume`, `destination_membership`, `destination`, `log`, `transformation`, and `user`. ([#40](https://github.com/fivetran/dbt_fivetran_log/pull/40))
# dbt_fivetran_log v0.5.1

## Features
This release just introduces Databricks compatibility! 🧱🧱

# dbt_fivetran_log v0.5.0
🎉 Official dbt v1.0.0 Compatibility Release 🎉
## 🚨 Breaking Changes 🚨
- Adjusts the `require-dbt-version` to now be within the range [">=1.0.0", "<2.0.0"]. Additionally, the package has been updated for dbt v1.0.0 compatibility. If you are using a dbt version <1.0.0, you will need to upgrade in order to leverage the latest version of the package.
  - For help upgrading your package, I recommend reviewing this GitHub repo's Release Notes on what changes have been implemented since your last upgrade.
  - For help upgrading your dbt project to dbt v1.0.0, I recommend reviewing dbt-labs [upgrading to 1.0.0 docs](https://docs.getdbt.com/docs/guides/migration-guide/upgrading-to-1-0-0) for more details on what changes must be made.
- Upgrades the package dependency to refer to the latest `dbt_fivetran_utils`. The latest `dbt_fivetran_utils` package also has a dependency on `dbt_utils` [">=0.8.0", "<0.9.0"].
  - Please note, if you are installing a version of `dbt_utils` in your `packages.yml` that is not in the range above then you will encounter a package dependency error.

## Additional Features
- Materializes the `fivetran_log__audit_table` incrementally, and employs partitioning for BigQuery users. As a non-incremental table, this model involved high runtimes for some users ([#27](https://github.com/fivetran/dbt_fivetran_log/issues/27))
  - If you would like to apply partitioning to the underlying source tables (ie the `LOG` table), refer to [Fivetran docs](https://fivetran.com/docs/destinations/bigquery/partition-table) on how to do so.
- Expands compatibility to Postgres!

# dbt_fivetran_log v0.5.0-b1
🎉 dbt v1.0.0 Compatibility Pre Release 🎉 An official dbt v1.0.0 compatible version of the package will be released once existing feature/bug PRs are merged.
## 🚨 Breaking Changes 🚨
- Adjusts the `require-dbt-version` to now be within the range [">=1.0.0", "<2.0.0"]. Additionally, the package has been updated for dbt v1.0.0 compatibility. If you are using a dbt version <1.0.0, you will need to upgrade in order to leverage the latest version of the package.
  - For help upgrading your package, I recommend reviewing this GitHub repo's Release Notes on what changes have been implemented since your last upgrade.
  - For help upgrading your dbt project to dbt v1.0.0, I recommend reviewing dbt-labs [upgrading to 1.0.0 docs](https://docs.getdbt.com/docs/guides/migration-guide/upgrading-to-1-0-0) for more details on what changes must be made.
- Upgrades the package dependency to refer to the latest `dbt_fivetran_utils`. The latest `dbt_fivetran_utils` package also has a dependency on `dbt_utils` [">=0.8.0", "<0.9.0"].
  - Please note, if you are installing a version of `dbt_utils` in your `packages.yml` that is not in the range above then you will encounter a package dependency error.

# dbt_fivetran_log v0.4.1

## 🚨 Breaking Changes
- n/a

## Bug Fixes
- Added logic in the `fivetran_log__connector_status` model to accommodate the way [priority-first syncs](https://fivetran.com/docs/getting-started/feature#priorityfirstsync) are currently logged. Now, each connector's `connector_health` field can be one of the following values:
    - "broken"
    - "incomplete"
    - "connected"
    - "paused"
    - "initial sync in progress"
    - "priority first sync"
Once your connector has completed its priority-first sync and begun syncing normally, it will be marked as `connected`.

## Features
- Added this changelog to capture iterations of the package!

## Under the Hood
- n/a
