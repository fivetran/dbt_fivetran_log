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

## Severity values in `fivetran_platform__errors_and_warnings`
The `fivetran_platform__errors_and_warnings` model unions error and warning events from two sources: the `log` table (standard connections) and the `connector_sdk_log` table (Connector SDK connections). Both sources report `WARNING` and `SEVERE`, while `ERROR` is reported only by the `connector_sdk_log` source. We pass each source's `severity_level` through as its raw value rather than normalizing or remapping it, so each event reflects exactly what its source reported. The `connector_type` column (`standard_connector` or `connector_sdk`) identifies which source a row came from.

We exclude events that are not attributable to a connection (where `connection_id` is null). The `log` table records some warning- and error-level events that are not connector events — for example, the dbt run output of a transformation job — and these carry no `connection_id`. The goal is for customers to monitor the severity of warnings and errors raised by their connectors, not warnings raised by the transformation jobs recorded in the log, so we require a non-null `connection_id` in both sources.

## Connector SDK log source
Not all customers have the `connector_sdk_log` source table, as it is only populated for accounts using the Fivetran Connector SDK. This source and its downstream logic are controlled by the `fivetran_platform_using_connector_sdk_log` variable, which defaults to `true`. If your destination does not contain the `connector_sdk_log` table, set this variable to `false` in your root `dbt_project.yml` to disable the source and exclude Connector SDK events from `fivetran_platform__errors_and_warnings`:

```yml
vars:
  fivetran_platform_using_connector_sdk_log: false ## Default is true. Set to false if the connector_sdk_log source table is not present in your destination.
```
