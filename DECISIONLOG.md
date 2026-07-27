# Decision Log

## Usage Cost vs Credits Used Sources
This package takes into consideration that the Fivetran pricing model has adjusted over the years. In particular, this package considers the old credit model (captured within the `credits_used` source) and the newer usage model (captured within the `usage_cost` source). By default, this package will dynamically check the mentioned sources in your destination and generate the respective staging models if the source is found. If the source is not found, the package will create a single row of null records in order to imitate the schema structure and ensure downstream transformations succeed. See the [does_table_exist()](macros/does_table_exist.sql) macro for more information on this dynamic functionality.

The below variables control the respective behaviors and may be overridden if desired. If overridden and configured to `false`, the models will still be materialized, but it will return no rows. This ensures the package does not generate records from the source, but still materializes the schema to ensure there is no run failure. The intention is that these variables are not needed to be configured, but if necessary they are available.

```yml
vars:
  fivetran_platform__usage_pricing: true ## Dynamically checks the source at runtime to set as either true or false. May be overridden using this variable if desired.
  fivetran_platform__credits_pricing: false ## Dynamically checks the source at runtime to set as either true or false. May be overridden using this variable if desired.
```

## Transformation Runs
Not all customers have the `transformation_runs` source table, particularly if they are not using Fivetran Transformations. Therefore, we leverage a new variable `fivetran_platform_using_transformations`, which automatically checks for the table. If it exists, the variable is set to True, which then persists the `transformation_runs` source table and related models and downstream fields. If the table doesn't exist, the staging `stg_fivetran_platform__transformation_runs` model will persist as an empty model and respective downstream fields will be null. 

In the case you have the `transformation_runs` source table but still wish to disable it to prevent it from being populated in the package, you may set `fivetran_platform_using_transformations` to False in your project.yml:

```yml
vars:
  fivetran_platform_using_transformations: false ## Dynamically checks the source at runtime to set as either true or false. May be overridden using this variable if desired.
```

## Records without a `connection_id` in `fivetran_platform__mar_table_history`
Some records in the `fivetran_platform__mar_table_history` model may lack an associated `connection_id`. This can occur for a few reasons. For example, the record may originate from a deleted connection or from HVR sources that do not populate this field.

Previously, we excluded these records under the assumption that they were erroneous. However, we've found cases where these rows provide valuable context, particularly for tracking metadata activity from legacy or nonstandard sources and now include them in the model. While this change will increase the number of rows returned, the added visibility supports more complete auditing and analysis.

## Connection recovery in `fivetran_platform__transformation_run_log`
The `connection_ids` and `connection_names` fields are primarily derived from the `schedule.integrations` array in the run log. This array is only populated for integrated schedules, so the majority of transformation runs (custom and cron schedules) leave it empty.

For QUICKSTART transformations, the `job_name` in `transformation_runs` reliably follows the `<connector type>/<connection name>` format. When `schedule.integrations` is empty, we recover the single connection by parsing the connection name from `job_name` and matching it to a connection in the same destination. This is a best-effort, single-connection recovery: QUICKSTART runs that target multiple connections always populate `schedule.integrations`, so they are unaffected. The fallback is scoped to QUICKSTART only, since other transformation types (such as DBT_CORE) use user-defined names that do not follow this format.

## Redshift connection limit in `fivetran_platform__transformation_run_log`
The `connection_ids` and `connection_names` fields are derived by unnesting the `schedule.integrations` array from the run log. Most warehouses use a native lateral-unnest function with no cap, but Redshift has no such primitive, so the `fivetran_log_connection_ids_unnested` macro iterates the array indices with a generated numbers table that produces `0-99` — capping connections per transformation job at **100 on Redshift only**. A job referencing more than 100 connections has the overflow silently dropped (the run still appears, just with an incomplete connection list). We chose 100 as this should leave comfortable headroom.

## Null `started_at` for older transformation runs
The `started_at` and `ended_at` fields in `fivetran_platform__transformation_run_log` are parsed from the top-level `startTime` and `endTime` keys in the run log. Older transformation run events do not include these top-level keys; instead, the timestamps are nested under `result.stepResults[0]`. For those older runs, `started_at` (and therefore `duration`) may be null, even though the run did capture a start time. We have chosen not to address this for now, since it only affects older/stale data.

## Severity values in `fivetran_platform__errors_and_warnings`
The `fivetran_platform__errors_and_warnings` model unions error and warning events from two sources: the `log` table (standard connections) and the `connector_sdk_log` table (Connector SDK connections). Both sources report `WARNING` and `SEVERE`, while `ERROR` is reported only by the `connector_sdk_log` source. We pass each source's `severity_level` through as its raw value rather than normalizing or remapping it, so each event reflects exactly what its source reported. The `connector_type` column (`standard_connector` or `connector_sdk`) identifies which source a row came from.

We exclude events that are not attributable to a connection (where `connection_id` is null). The `log` table records some warning- and error-level events that are not connector events — for example, the dbt run output of a transformation job — and these carry no `connection_id`. The goal is for customers to monitor the severity of warnings and errors raised by their connectors, not warnings raised by the transformation jobs recorded in the log, so we require a non-null `connection_id` in both sources.

## Resolving connection names in `fivetran_platform__audit_trail_enriched`
The `audit_trail` source identifies connections by `connection_id`, but `stg_fivetran_platform__connection` is unique on `(connection_name, destination_id)`, so one `connection_id` can span multiple rows (e.g. after a rename or move). We deduplicate the connection lookup to the active, most recently set up record per `connection_id` to avoid fanning out audit events. A connection therefore resolves to its current name; no history is lost, as renames are still captured in `old_values`/`new_values`.
