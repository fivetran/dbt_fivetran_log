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
    <a alt="Fivetran Quickstart Compatible"
        href="https://fivetran.com/docs/transformations/dbt/quickstart">
        <img src="https://img.shields.io/badge/Fivetran_Quickstart_Compatible%3F-yes-green.svg" /></a>
</p>

# Fivetran Platform dbt Package ([Docs](https://fivetran.github.io/dbt_fivetran_log/))
# 📣 What does this dbt package do?
- Generates a comprehensive data dictionary of your Fivetran Platform connector (previously called Fivetran Log) data via the [dbt docs site](https://fivetran.github.io/dbt_fivetran_log/)
- Produces staging models in the format described by [this ERD](https://fivetran.com/docs/logs/fivetran-log#schemainformation) which clean, test, and prepare your Fivetran data from [Fivetran's free connector](https://fivetran.com/docs/applications/fivetran-log) and generates analysis ready end models.
- The above mentioned models enable you to better understand how you are spending money in Fivetran according to our [consumption-based pricing model](https://fivetran.com/docs/getting-started/consumption-based-pricing) as well as providing details about the performance and status of your Fivetran connectors and transformations. This is achieved by:
    - Displaying consumption data at the table, connector, destination, and account levels
    - Providing a history of measured free and paid monthly active rows (MAR), credit consumption, and the relationship between the two
    - Creating a history of vital daily events for each connector
    - Surfacing an audit log of records inserted, deleted, an updated in each table during connector syncs

<!--section="fivetran_platform_transformation_model"-->
Refer to the table below for a detailed view of all models materialized by default within this package. Additionally, check out our [docs site](https://fivetran.github.io/dbt_fivetran_log/#!/overview/fivetran_platform?g_v=1&g_e=seeds) for more details about these models. 
## Models

| **model**                  | **description**                                                                                                                                               |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [fivetran_platform__connector_status](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__connector_status)        | Each record represents a connector loading data into a destination, enriched with data about the connector's data sync status.                                          |
| [fivetran_platform__transformation_status](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__transformation_status)     | Each record represents a transformation, enriched with data about the transformation's last sync and any tables whose new data triggers the transformation to run. |
| [fivetran_platform__mar_table_history](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__mar_table_history)     | Each record represents a table's free, paid, and total volume for a month, complete with data about its connector and destination.                             |
| [fivetran_platform__usage_mar_destination_history](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__usage_mar_destination_history)    | Table of each destination's usage and active volume, per month. Includes the usage per million MAR and MAR per usage. Usage either refers to a dollar or credit amount, depending on customer's pricing model. Read more about the relationship between usage and MAR [here](https://www.fivetran.com/legal/service-consumption-table).                             |
| [fivetran_platform__connector_daily_events](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__connector_daily_events)    | Each record represents a daily measurement of the API calls, schema changes, and record modifications made by a connector, starting from the date on which the connector was set up.                            |
| [fivetran_platform__schema_changelog](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__schema_changelog)    | Each record represents a schema change (altering/creating tables, creating schemas, and changing schema configurations) made to a connector and contains detailed information about the schema change event.                           |
| [fivetran_platform__audit_table](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__audit_table)    | Replaces the deprecated [`_fivetran_audit` table](https://fivetran.com/docs/getting-started/system-columns-and-tables#audittables). Each record represents a table being written to during a connector sync. Contains timestamps related to the connector and table-level sync progress and the sum of records inserted/replaced, updated, and deleted in the table.                             |
<!--section-end-->


# 🎯 How do I use the dbt package?
## Step 1: Pre-Requisites
- **Connector**: Have the Fivetran Platform connector syncing data into your warehouse. 
- **Database support**: This package has been tested on **BigQuery**, **Snowflake**, **Redshift**, **Postgres**, and **Databricks**. Ensure you are using one of these supported databases.

### Databricks Dispatch Configuration
If you are using a Databricks destination with this package you will need to add the below (or a variation of the below) dispatch configuration within your `dbt_project.yml`. This is required in order for the package to accurately search for macros within the `dbt-labs/spark_utils` then the `dbt-labs/dbt_utils` packages respectively.
```yml
dispatch:
  - macro_namespace: dbt_utils
    search_order: ['spark_utils', 'dbt_utils']
```

### Database Incremental Strategies 
Some of the end models in this package are materialized incrementally. We have chosen `insert_overwrite` as the default strategy for **BigQuery** and **Databricks** databases, as it is only available for these dbt adapters. For **Snowflake**, **Redshift**, and **Postgres** databases, we have chosen `delete+insert` as the default strategy.

`insert_overwrite` is our preferred incremental strategy because it will be able to properly handle updates to records that exist outside the immediate incremental window. That is, because it leverages partitions, `insert_overwrite` will appropriately update existing rows that have been changed upstream instead of inserting duplicates of them--all without requiring a full table scan.

`delete+insert` is our second-choice as it resembles `insert_overwrite` but lacks partitions. This strategy works most of the time and appropriately handles incremental loads that do not contain changes to past records. However, if a past record has been updated and is outside of the incremental window, `delete+insert` will insert a duplicate record. 😱
> Because of this, we highly recommend that **Snowflake**, **Redshift**, and **Postgres** users periodically run a `--full-refresh` to ensure a high level of data quality and remove any possible duplicates.

## Step 2: Installing the Package
Include the following Fivetran Platform package version range in your `packages.yml`
> Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yaml
packages:
  - package: fivetran/fivetran_log
    version: [">=1.1.0", "<1.2.0"]
```

> Note that altough the source connector is now "Fivetran Platform", the package retains the old name of "fivetran_log".

## Step 3: Define Database and Schema Variables
By default, this package will run using your target database and the `fivetran_log` schema. If this is not where your Fivetran Platform data is (perhaps your fivetran platform schema is `fivetran_platform`), add the following configuration to your root `dbt_project.yml` file:

```yml
vars:
    fivetran_platform_database: your_database_name # default is your target.database
    fivetran_platform_schema: your_schema_name # default is fivetran_log
```

## Step 4: Disable Models for Non Existent Sources
If you have never created Fivetran-orchestrated [basic SQL transformations](https://fivetran.com/docs/transformations/basic-sql), your source data will not contain the `transformation` and `trigger_table` tables. Moreover, if you have only created *scheduled* basic transformations that are not triggered by table syncs, your source data will not contain the `trigger_table` table (though it will contain `transformation`). 

Additionally, if you do not leverage Fivetran RBAC, then you will not have the `user` or `destination_membership` sources. To disable the corresponding functionality in the package, you must add the following variable(s) to your root `dbt_project.yml` file. By default, all variables are assumed to be `true`:

```yml
vars:
    fivetran_platform_using_transformations: false # this will disable all transformation + trigger_table logic
    fivetran_platform_using_triggers: false # this will disable only trigger_table logic 
    fivetran_platform_using_destination_membership: false # this will disable only the destination membership logic
    fivetran_platform_using_user: false # this will disable only the user logic
```

## (Optional) Step 5: Additional Configurations
<details><summary>Expand for configurations</summary>

### Configuring Fivetran Error and Warning Messages
Some users may wish to exclude Fivetran error and warnings messages from the final `fivetran_platform__connector_status` model due to the length of the message. To disable the `errors_since_last_completed_sync` and `warnings_since_last_completed_sync` fields from the final model you may add the following variable to you to your root `dbt_project.yml` file. By default, this variable is assumed to be `true`:

```yml
vars:
    fivetran_platform_using_sync_alert_messages: false # this will disable only the sync alert messages within the connector status model
```
### Change the Build Schema
By default this package will build the Fivetran staging models within a schema titled (<target_schema> + `_stg_fivetran_platform`)  and the Fivetran Platform final models within your <target_schema> + `_fivetran_platform` in your target database. If this is not where you would like you Fivetran staging and final models to be written to, add the following configuration to your root `dbt_project.yml` file:

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
    fivetran_platform_<default_table_name>_identifier: your_table_name 
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
- Have questions or want to be part of the community discourse? Create a post in the [Fivetran community](https://community.fivetran.com/t5/user-group-for-dbt/gh-p/dbt-user-group) and our team along with the community can join in on the discussion!
