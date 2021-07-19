[![Apache License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) ![dbt Logo and Version](https://img.shields.io/static/v1?logo=dbt&label=dbt-version&message=0.20.x&color=orange)
# Fivetran Log ([docs](https://fivetran.github.io/dbt_fivetran_log/#!/overview))

This package models Fivetran Log data from [our free internal connector](https://fivetran.com/docs/logs/fivetran-log). It uses account-level data in the format described by [this ERD](https://fivetran.com/docs/logs/fivetran-log#schemainformation).

This package helps you understand:
* How you are spending money in Fivetran according to our [consumption-based pricing model](https://fivetran.com/docs/getting-started/consumption-based-pricing). We display consumption data at the table, connector, destination, and account levels.
* How your data is flowing in Fivetran:
    * Connector health and sync statuses
    * Transformation run statuses
    * Daily API calls, schema changes, and records modified
    * Table-level details of each connector sync

The package's main goals are to:
* Create a history of measured monthly active rows (MAR), credit consumption, and the relationship between the two
* Enhance the connector table with sync metrics and relevant alert messages
* Enhance the transformation table with run metrics
* Create a history of vital daily events for each connector
* Create an audit log of records inserted, deleted, an updated in each table during connector syncs

> Note: An earlier version of this package unioned destination-level connector data to the account level. As of [December 2020](https://fivetran.com/docs/logs/fivetran-log/changelog#december2020), the Fivetran Log now supports the creation of account-level connectors. We have removed the Fivetran Log dbt package's unioning functionality and recommend that users resync their Log connectors at the account level.

## Models

| **model**                  | **description**                                                                                                                                               |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [fivetran_log__connector_status](models/fivetran_log__connector_status.sql)        | Each record represents a connector loading data into a destination, enriched with data about the connector's data sync status.                                          |
| [fivetran_log__transformation_status](models/fivetran_log_transformation_status.sql)     | Each record represents a transformation, enriched with data about the transformation's last sync and any tables whose new data triggers the transformation to run. |
| [fivetran_log__mar_table_history](models/fivetran_log__mar_table_history.sql)     | Each record represents a table's active volume for a month, complete with data about its connector and destination.                             |
| [fivetran_log__credit_mar_destination_history](models/fivetran_log__credit_mar_destination_history.sql)    | Each record represents a destination's consumption by showing its MAR, total credits used, and credits per millions MAR.                             |
| [fivetran_log__connector_daily_events](models/fivetran_log__connector_daily_events.sql)    | Each record represents a daily measurement of the API calls, schema changes, and record modifications made by a connector, starting from the date on which the connector was set up.                            |
| [fivetran_log__schema_changelog](models/fivetran_log__schema_changelog.sql)    | Each record represents a schema change (altering/creating tables, creating schemas, and changing schema configurations) made to a connector and contains detailed information about the schema change event.                           |
| [fivetran_log__audit_table](models/fivetran_log__audit_table.sql)    | Replaces the deprecated [`fivetran_audit` table](https://fivetran.com/docs/getting-started/system-columns-and-tables#audittables). Each record represents a table being written to during a connector sync. Contains timestamps related to the connector and table-level sync progress and the sum of records inserted/replaced, updated, and deleted in the table.                             |


## Installation Instructions
`dbt_fivetran_log` currently supports `dbt 0.20.x`.

Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

Include in your `packages.yml`

```yaml
packages:
  - package: fivetran/fivetran_log
    version: [">=0.4.0", "<0.5.0"]
```

## Configuration
By default, this package will run using your target database and the `fivetran_log` schema. If this is not where your Fivetran Log data is, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
config-version: 2

vars:
  fivetran_log:
    fivetran_log_database: your_database_name
    fivetran_log_schema: your_schema_name 
```

### Disabling Transformation Models
If you have never created Fivetran-orchestrated [basic SQL transformations](https://fivetran.com/docs/transformations/basic-sql), your source data will not contain the `transformation` and `trigger_table` tables. Moreover, if you have only created *scheduled* basic transformations that are not triggered by table syncs, your source data will not contain the `trigger_table` table (though it will contain `transformation`). 

To disable the corresponding functionality in the package, you must add the following variable(s) to your `dbt_project.yml` file. By default, all variables are assumed to be `true`:

```yml
# dbt_project.yml

...
config-version: 2

vars:
  fivetran_log:
    fivetran_log_using_transformations: false # this will disable all transformation + trigger_table logic
    fivetran_log_using_triggers: false # this will disable only trigger_table logic 
```

### Disabling Fivetran Error and Warning Messages
Some users may wish to exclude Fivetran error and warnings messages from the final `fivetran_log__connector_status` model due to the length of the message. To disable the `errors_since_last_completed_sync` and `warnings_since_last_completed_sync` fields from the final model you may add the following variable to you to your `dbt_project.yml` file. By default, this variable is assumed to be `true`:
```yml
# dbt_project.yml

...
config-version: 2

vars:
  fivetran_log:
    fivetran_log_using_sync_alert_messages: false # this will disable only the sync alert messages within the connector status model
```

### Changing the Build Schema
By default this package will build the Fivetran Log staging models within a schema titled (<target_schema> + `_stg_fivetran_log`)  and the Fivetran Log final models within your <target_schema> + `_fivetran_log` in your target database. If this is not where you would like you Fivetran Log staging and final models to be written to, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
models:
  fivetran_log:
    +schema: my_new_final_models_schema # leave blank for just the target_schema
    staging:
      +schema: my_new_staging_models_schema # leave blank for just the target_schema

```

*Read more about using custom schemas in dbt [here](https://docs.getdbt.com/docs/building-a-dbt-project/building-models/using-custom-schemas).*

## Contributions
Don't see a model or specific metric you would have liked to be included? Notice any bugs when installing 
and running the package? If so, we highly encourage and welcome contributions to this package! 
Please create issues or open PRs against `master`. See [the Discourse post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) for information on how to contribute to a package.

## Database Support
This package has been tested on BigQuery, Snowflake and Redshift.

## Resources:
- Provide [feedback](https://www.surveymonkey.com/r/DQ7K7WW) on our existing dbt packages or what you'd like to see next
- Have questions, feedback, or need help? Book a time during our office hours [using Calendly](https://calendly.com/fivetran-solutions-team/fivetran-solutions-team-office-hours) or email us at solutions@fivetran.com
- Find all of Fivetran's pre-built dbt packages in our [dbt hub](https://hub.getdbt.com/fivetran/)
- Learn how to orchestrate [dbt transformations with Fivetran](https://fivetran.com/docs/transformations/dbt)
- Learn more about Fivetran overall [in our docs](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the dbt docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the dbt blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
