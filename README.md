<!--section="fivetran-log_transformation_model"-->
# Fivetran Log dbt Package

<p align="left">
    <a alt="License"
        href="https://github.com/fivetran/dbt_fivetran_log/blob/main/LICENSE">
        <img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" /></a>
    <a alt="dbt-core">
        <img src="https://img.shields.io/badge/dbt_Core™_version->=1.3.0,_<3.0.0-orange.svg" /></a>
    <a alt="Maintained?">
        <img src="https://img.shields.io/badge/Maintained%3F-yes-green.svg" /></a>
    <a alt="PRs">
        <img src="https://img.shields.io/badge/Contributions-welcome-blueviolet" /></a>
    <a alt="Fivetran Quickstart Compatible"
        href="https://fivetran.com/docs/transformations/data-models/quickstart-management#quickstartmanagement">
        <img src="https://img.shields.io/badge/Fivetran_Quickstart_Compatible%3F-yes-green.svg" /></a>
</p>

This dbt package transforms data from Fivetran's Fivetran Log connector into analytics-ready tables.

## Resources

- Number of materialized models¹: 19
- Connector documentation
  - [Fivetran Log connector documentation](https://fivetran.com/docs/connectors/applications/fivetran-log)
  - [Fivetran Log ERD](https://fivetran.com/docs/connectors/applications/fivetran-log#schemainformation)
- dbt package documentation
  - [GitHub repository](https://github.com/fivetran/dbt_fivetran_log)
  - [dbt Docs](https://fivetran.github.io/dbt_fivetran_log/#!/overview)
  - [DAG](https://fivetran.github.io/dbt_fivetran_log/#!/overview?g_v=1)
  - [Changelog](https://github.com/fivetran/dbt_fivetran_log/blob/main/CHANGELOG.md)

## What does this dbt package do?
This package enables you to better understand how you are spending money in Fivetran according to our consumption-based pricing model and provides details about the performance and status of your Fivetran connections. It creates enriched models with metrics focused on consumption data, monthly active rows (MAR), credit consumption, connection events, schema changes, and audit logs.

> dbt Core >= 1.9.6 is required to run freshness tests out of the box. See other options [here](https://github.com/fivetran/dbt_fivetran_log/blob/main/CHANGELOG.md#breaking-change-for-dbt-core--196).

### Output schema
Final output tables are generated in the following target schema:

```
<your_database>.<connector/schema_name>_fivetran_log
```

### Final output tables

By default, this package materializes the following final tables:

| Table | Description |
| :---- | :---- |
| [fivetran_platform__connection_status](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__connection_status) | Each record represents a connection loading data into a destination, enriched with data about the connection's data sync status. |
| [fivetran_platform__mar_table_history](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__mar_table_history) | Each record represents a table's free, paid, and total volume for a month, complete with data about its connection and destination. |
| [fivetran_platform__usage_history](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__usage_history) | Table of each destination's usage and active volume, per month. Includes the usage per million MAR and MAR per usage. Usage either refers to a dollar or credit amount, depending on customer's pricing model. Read more about the relationship between usage and MAR [here](https://www.fivetran.com/legal/service-consumption-table). |
| [fivetran_platform__connection_daily_events](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__connection_daily_events) | Each record represents a daily measurement of the API calls, schema changes, and record modifications made by a connection, starting from the date on which the connection was set up. |
| [fivetran_platform__schema_changelog](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__schema_changelog) | Each record represents a schema change (altering/creating tables, creating schemas, and changing schema configurations) made to a connection and contains detailed information about the schema change event. |
| [fivetran_platform__audit_table](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__audit_table) | Replaces the deprecated [`_fivetran_audit` table](https://fivetran.com/docs/getting-started/system-columns-and-tables#audittables). Each record represents a table being written to during a connection sync. Contains timestamps related to the connection and table-level sync progress and the sum of records inserted/replaced, updated, and deleted in the table. |
| [fivetran_platform__audit_user_activity](https://fivetran.github.io/dbt_fivetran_log/#!/model/model.fivetran_log.fivetran_platform__audit_user_activity) | Each record represents a user-triggered action in your Fivetran instance. This table is intended for audit-trail purposes, as it can be very helpful when trying to trace a user action to a [log event](https://fivetran.com/docs/logs#logeventlist) such as a schema change, sync frequency update, manual update, broken connection, etc. |

¹ Each Quickstart transformation job run materializes these models if all components of this data model are enabled. This count includes all staging, intermediate, and final models materialized as `view`, `table`, or `incremental`.

---

## Prerequisites

To use this dbt package, you must have the following:

- At least one Fivetran Fivetran Log connection syncing data into your destination.
- A **BigQuery**, **Snowflake**, **Redshift**, **Postgres**, **Databricks**, or **SQL Server** destination.

## How do I use the dbt package?
You can either add this dbt package in the Fivetran dashboard or import it into your dbt project:

- To add the package in the Fivetran dashboard, follow our [Quickstart guide](https://fivetran.com/docs/transformations/data-models/quickstart-management).
- To add the package to your dbt project, follow the setup instructions in the dbt package's [README file](https://github.com/fivetran/dbt_fivetran_log/blob/main/README.md#how-do-i-use-the-dbt-package) to use this package.

<!--section-end-->

### Install the Package
Include the following Fivetran Platform package version range in your `packages.yml`
> Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.
```yml
packages:
  - package: fivetran/fivetran_log
    version: [">=2.5.0", "<2.6.0"]
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
If you do not leverage Fivetran RBAC, then you will not have the `user` or `destination_membership` source tables. The `user` and `destination_membership` are enabled by default. Therefore in order to switch the default configurations, you must add the following variable(s) to your root `dbt_project.yml` file for the respective source tables you wish to disable:

```yml
vars:
    fivetran_platform_using_destination_membership: false # Default is true. This will disable only the destination membership logic
    fivetran_platform_using_user: false # Default is true. This will disable only the user logic
```

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
