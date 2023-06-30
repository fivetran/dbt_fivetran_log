# Decision Log

## Usage Cost vs Credits Used Sources
This package takes into consideration that the Fivetran pricing model has adjusted over the years. In particular, this package considers the old credit model (captured within the `credits_used` source) and the newer usage model (captured within the `usage_cost` source). By default, this package will dynamically check the mentioned sources in your destination and generate the respective staging models if the source is found. If the source is not found, the package will create a single row of null records in order to imitate the schema structure and ensure downstream transformations succeed. See the [does_table_exist()](macros/does_table_exist.sql) macro for more information on this dynamic functionality.

The below variables control the respective behaviors and may be overridden if desired. If overridden and configured to `false`, the models will still be materialized, but with only a single null row. This ensures the package does not generate records from the source, but still materializes the schema to ensure there is no run failure. The intention is that these variables are not needed to be configured, but if necessary they are available.

```yml
vars:
  fivetran_platform__usage_pricing: true ## Dynamically checks the source at runtime to set as either true or false. May be overridden using this variable if desired.
  fivetran_platform__credits_pricing: false ## Dynamically checks the source at runtime to set as either true or false. May be overridden using this variable if desired.
```