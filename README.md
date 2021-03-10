# Fivetran Log ([docs](https://fivetran-log-dbt-package.netlify.app/#!/overview))

This package models Fivetran Log data from [our free internal connector](https://fivetran.com/docs/logs/fivetran-log). It uses account-level data in the format described by [this ERD](https://docs.google.com/presentation/d/1lny-kFwJIvOCbKky3PEvEQas4oaHVVTahj3OTRONpu8/?usp=sharing).

This package helps you understand:
* How you are spending money in Fivetran according to our [consumption-based pricing model](https://fivetran.com/docs/getting-started/consumption-based-pricing). We display consumption data at the table, connector, destination, and account levels.
* How your data is flowing in Fivetran:
    * Connector health and sync statuses
    * Transformation run statuses
    * Daily API calls

The package's main goals are to:
* Create a history of measured monthly active rows (MAR), credit consumption, and the relationship between the two
* Enhance the connector table with sync metrics and relevant alert messages
* Enhance the transformation table with run metrics
* Create a history of daily API calls for each connector

> Note: An earlier version of this package unioned destination-level connector data to the account level. As of [December 2020](https://fivetran.com/docs/logs/fivetran-log/changelog#december2020), the Fivetran Log now supports the creation of account-level connectors. We have removed the Fivetran Log dbt package's unioning functionality and recommend that users resync their Log connectors at the account level.

## Models

| **model**                  | **description**                                                                                                                                               |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| fivetran\_log\_connector\_status        | Each record represents a connector loading data into a destination, enriched with data about the connector's status and the status of its data flow.                                          |
| fivetran\_log\_transformation\_status     | Each record represents a transformation, enriched with data about the transformation's last sync and any tables whose new data triggers the transformation to run. |
| fivetran\_log\_mar\_table\_history     | Each record represents a table's active volume for a month, complete with data about its connector and destination.                             |
| fivetran\_log\_credit\_mar\_history    | Each record represents a destination's consumption by showing its MAR, total credits used, and credits per millions MAR.                             |
| fivetran\_log\_connector\_daily_api\_calls    | Each record represents a daily measurement of the API calls made by a connector, starting from the date on which the connector was set up.                            |


## Installation Instructions
Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

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

## Disabling Transformation Models
If you have never created Fivetran-orchestrated transformations, your source data will not contain the `transformation` and `trigger_table` tables. In this case, the package will still create transformation models, but they will be completely empty. 

If you do not want these empty tables in your warehouse, add the following configuration to your `dbt_project.yml` file to disable these models:

```yml
# dbt_project.yml

...
config-version: 2

models:
  fivetran_log:
    fivetran_log_transformation_status:
      +enabled: false
    staging:
      stg_fivetran_log_trigger_table:
        +enabled: false
      stg_fivetran_log_transformation:
        +enabled: false
```

### Changing the Build Schema
By default this package will build the Fivetran Log staging models within a schema titled (<target_schema> + `_stg_fivetran_log`)  and the Fivetran Log final models within your <target_schema> in your target database. If this is not where you would like you Fivetran Log staging and final models to be written to, add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
models:
  fivetran_log:
    +schema: my_new_final_models_schema
    staging:
      +schema: my_new_staging_models_schema

```

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