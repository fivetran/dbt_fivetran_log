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
