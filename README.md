<p align="center">
    <a alt="License"
        href="https://github.com/fivetran/dbt_fivetran_log/blob/main/LICENSE">
        <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" /></a>
    <a alt="dbt-core">
        <img src="https://img.shields.io/badge/dbt_Core™_version->=1.3.0_<2.0.0-orange.svg" /></a>
    <a alt="Maintained?">
        <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" /></a>
    <a alt="PRs">
        <img src="https://img.shields.io/badge/Contributions-welcome-blueviolet" /></a>
</p>

# Fivetran Log dbt Package ([Docs](https://fivetran.github.io/dbt_fivetran_log/))
# 📣 What does this dbt package do?
- Generates a comprehensive data dictionary of your Fivetran Log data via the [dbt docs site](https://fivetran.github.io/dbt_fivetran_log/)
- Produces staging models in the format described by [this ERD](https://fivetran.com/docs/logs/fivetran-log#schemainformation) which clean, test, and prepare your Fivetran Log data from [Fivetran's free connector](https://fivetran.com/docs/applications/fivetran-log) and generates analysis ready end models.
- The above mentioned models enable you to better understand how you are spending money in Fivetran according to our [consumption-based pricing model](https://fivetran.com/docs/getting-started/consumption-based-pricing) as well as providing details about the performance and status of your Fivetran connectors and transformations. This is achieved by:
    - Displaying consumption data at the table, connector, destination, and account levels
    - Providing a history of measured free and paid monthly active rows (MAR), credit consumption, and the relationship between the two
    - Creating a history of vital daily events for each connector
    - Surfacing an audit log of records inserted, deleted, an updated in each table during connector syncs

Refer to the table below for a detailed view of all models materialized by default within this package. Additionally, check out our [docs site](https://fivetran.github.io/dbt_fivetran_log/#!/overview/fivetran_log?g_v=1&g_e=seeds) for more details about these models. 
## Models

| **model**                  | **description**                                                                                                                                               |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [fivetran_log__connector_status](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_log__connector_status)        | Each record represents a connector loading data into a destination, enriched with data about the connector's data sync status.                                          |
| [fivetran_log__transformation_status](https://github.com/fivetran/dbt_fivetran_log/blob/main/models/fivetran_log__transformation_status.sql)     | Each record represents a transformation, enriched with data about the transformation's last sync and any tables whose new data triggers the transformation to run. |
| [fivetran_log__mar_table_history](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_log__mar_table_history)     | Each record represents a table's free, paid, and total volume for a month, complete with data about its connector and destination.                             |
| [fivetran_log__usage_mar_destination_history](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_log__usage_mar_destination_history)    | Table of each destination's usage and active volume, per month. Includes the usage per million MAR and MAR per usage. Usage either refers to a dollar or credit amount, depending on customer's pricing model. Read more about the relationship between usage and MAR [here](https://www.fivetran.com/legal/service-consumption-table).                             |
| [fivetran_log__connector_daily_events](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_log__connector_daily_events)    | Each record represents a daily measurement of the API calls, schema changes, and record modifications made by a connector, starting from the date on which the connector was set up.                            |
| [fivetran_log__schema_changelog](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_log__schema_changelog)    | Each record represents a schema change (altering/creating tables, creating schemas, and changing schema configurations) made to a connector and contains detailed information about the schema change event.                           |
| [fivetran_log__audit_table](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_log__audit_table)    | Replaces the deprecated [`fivetran_audit` table](https://fivetran.com/docs/getting-started/system-columns-and-tables#audittables). Each record represents a table being written to during a connector sync. Contains timestamps related to the connector and table-level sync progress and the sum of records inserted/replaced, updated, and deleted in the table.                             |

# 🎯 How do I use the dbt package?
## Step 1: Pre-Requisites
- **Connector**: Have the Fivetran Fivetran Log connector syncing data into your warehouse. 
- **Database support**: This package has been tested on **BigQuery**, **Snowflake**, **Redshift**, **Postgres**, and **Databricks**. Ensure you are using one of these supported databases.

### Databricks Dispatch Configuration
If you are using a Databricks destination with this package you will need to add the below (or a variation of the below) dispatch configuration within your `dbt_project.yml`. This is required in order for the package to accurately search for macros within the `dbt-labs/spark_utils` then the `dbt-labs/dbt_utils` packages respectively.
```yml
dispatch:
  - macro_namespace: dbt_utils
    search_order: ['spark_utils', 'dbt_utils']
```

## Step 2: Installing the Package
Include the following fivetran_log package version in your `packages.yml`
> Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yaml
packages:
  - package: fivetran/fivetran_log
    version: [">=0.7.0", "<0.8.0"]
```
## Step 3: Define Database and Schema Variables
By default, this package will run using your target database and the `fivetran_log` schema. If this is not where your Fivetran Log data is (perhaps your fivetran_log schema is `fivetran_log_fivetran`), add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    fivetran_log_database: your_database_name
    fivetran_log_schema: your_schema_name 
```
## Step 4: Disable Models for Non Existent Sources
If you have never created Fivetran-orchestrated [basic SQL transformations](https://fivetran.com/docs/transformations/basic-sql), your source data will not contain the `transformation` and `trigger_table` tables. Moreover, if you have only created *scheduled* basic transformations that are not triggered by table syncs, your source data will not contain the `trigger_table` table (though it will contain `transformation`). 

Additionally, if you do not leverage Fivetran RBAC, then you will not have the `user`, `account_membership`, or `destination_membership` sources. To disable the corresponding functionality in the package, you must add the following variable(s) to your root `dbt_project.yml` file. By default, all variables are assumed to be `true`:

```yml
vars:
    fivetran_log_using_transformations: false # this will disable all transformation + trigger_table logic
    fivetran_log_using_triggers: false # this will disable only trigger_table logic 
    fivetran_log_using_account_membership: false # this will disable only the account membership logic
    fivetran_log_using_destination_membership: false # this will disable only the destination membership logic
    fivetran_log_using_user: false # this will disable only the user logic
```

## (Optional) Step 5: Additional Configurations
<details><summary>Expand for configurations</summary>

### Configuring Fivetran Error and Warning Messages
Some users may wish to exclude Fivetran error and warnings messages from the final `fivetran_log__connector_status` model due to the length of the message. To disable the `errors_since_last_completed_sync` and `warnings_since_last_completed_sync` fields from the final model you may add the following variable to you to your root `dbt_project.yml` file. By default, this variable is assumed to be `true`:

```yml
vars:
    fivetran_log_using_sync_alert_messages: false # this will disable only the sync alert messages within the connector status model
```

### Specifying Usage Cost vs Credits Used Sources
This package takes into consideration that the Fivetran pricing model has adjusted over the years. In particular, this package considers the old credit model (captured within the `credits_used` source) and the newer usage model (captured within the `usage_cost` source). By default, this package will dynamically check the mentioned sources in your destination and generate the respective staging models if the source is found. If the source is not found, the package will create a single row of null records in order to imitate the schema structure and ensure downstream transformations succeed. See the [does_table_exist()](fivetran_log__usage_pricing) macro for more information on this dynamic functionality.

If for any reason you want to turn off the dynamic functionality of the package and use only one of the two sources (`usage_cost` or `credits_used`) you may use the respective below variables to control the package behavior. Please note, it is highly encouraged to ensure at least one of the variables is defined to `true`. The package is intended to work when both are `true` or when at least one is `true`.

```yml
vars:
  fivetran_log__usage_pricing: true ## Dynamically checks the source at runtime to set as either true or false. May be overridden using this variable if desired.
  fivetran_log__credits_pricing: true ## Dynamically checks the source at runtime to set as either true or false. May be overridden using this variable if desired.
```

### Change the Build Schema
By default this package will build the Fivetran Log staging models within a schema titled (<target_schema> + `_stg_fivetran_log`)  and the Fivetran Log final models within your <target_schema> + `_fivetran_log` in your target database. If this is not where you would like you Fivetran Log staging and final models to be written to, add the following configuration to your root `dbt_project.yml` file:

```yml
models:
  fivetran_log:
    +schema: my_new_final_models_schema # leave blank for just the target_schema
    staging:
      +schema: my_new_staging_models_schema # leave blank for just the target_schema
```
    
### Change the Source Table References
If an individual source table has a different name than expected (see this projects [dbt_project.yml](https://github.com/fivetran/dbt_fivetran_log/blob/main/dbt_project.yml) variable declarations for expected names), provide the name of the table as it appears in your warehouse to the respective variable as identified below:
```yml
vars:
    fivetran_log_<default_table_name>_identifier: your_table_name 
```

### Databricks Additional Configuration
If you are using a Databricks destination with this package you will need to add the below (or a variation of the below) dispatch configuration within your root `dbt_project.yml`. This is required in order for the package to accurately search for macros within the `dbt-labs/spark_utils` then the `dbt-labs/dbt_utils` packages respectively.
```yml
dispatch:
  - macro_namespace: dbt_utils
    search_order: ['spark_utils', 'dbt_utils']
```

</details>

## (Optional) Step 6: Orchestrate your models with Fivetran Transformations for dbt Core™
<details><summary>Expand for details</summary>
<br>
    
Fivetran offers the ability for you to orchestrate your dbt project through [Fivetran Transformations for dbt Core™](https://fivetran.com/docs/transformations/dbt). Refer to the linked docs for more information on how to setup your project for orchestration through Fivetran. 
</details>
    
# 🔍 Does this package have dependencies?
This dbt package is dependent on the following dbt packages. Please be aware that these dependencies are installed by default within this package. For more information on the below packages, refer to the [dbt hub](https://hub.getdbt.com/) site.
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
          
# 🙌 How is this package maintained and can I contribute?
## Package Maintenance
The Fivetran team maintaining this package **only** maintains the latest version of the package. We highly recommend you stay consistent with the [latest version](https://hub.getdbt.com/fivetran/fivetran_log/latest/) of the package and refer to the [CHANGELOG](https://github.com/fivetran/dbt_fivetran_log/blob/main/CHANGELOG.md) and release notes for more information on changes across versions.

## Contributions
These dbt packages are developed by a small team of analytics engineers at Fivetran. However, the packages are made better by community contributions! 

We highly encourage and welcome contributions to this package. Check out [this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) on the best workflow for contributing to a package!

# 🏪 Are there any resources available?
- If you encounter any questions or want to reach out for help, please refer to the [GitHub Issue](https://github.com/fivetran/dbt_fivetran_log/issues/new/choose) section to find the right avenue of support for you.
- If you would like to provide feedback to the dbt package team at Fivetran, or would like to request a future dbt package to be developed, then feel free to fill out our [Feedback Form](https://www.surveymonkey.com/r/DQ7K7WW).
- Have questions or want to just say hi? Book a time during our office hours [here](https://calendly.com/fivetran-solutions-team/fivetran-solutions-team-office-hours) or send us an email at solutions@fivetran.com.
