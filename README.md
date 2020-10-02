# Fivetran Log 

This package models Fivetran Log data from [our free internal connector](https://fivetran.com/docs/logs/fivetran-log). It uses destination-level data in the format described by [this ERD](https://docs.google.com/presentation/d/1lny-kFwJIvOCbKky3PEvEQas4oaHVVTahj3OTRONpu8/?usp=sharing) and unions the data to the account level, if needed.

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
* Union log data across destinations

> Note: The Fivetran Log Connector dbt package is compatible with BigQuery, Redshift, and Snowflake.
>
> Though compatible with each individual kind of warehouse, the package is not *cross-compatible*. For example, you can union log data across various BigQuery destinations, but not between BigQuery *and* Snowflake destinations.

## Models
See the Fivetran Log package [docs site](https://fivetran-log-dbt-package.netlify.app/#!/overview).

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
### Using a single destination 
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

### Using multiple destinations 
#### 0. Ensure dbt access to all destinations
First, you will need to ensure that your target profile (whose credentials are defined in your `~/.dbt/profiles.yml` file) has access to query all of the destinations that you are loading log data from.

> Note: If you are using multiple BigQuery databases, you must use the OAuth authentication method instead of service accounts in `profiles.yml`. Both methods are included in [dbt's BigQuery profile documentation](https://docs.getdbt.com/reference/warehouse-profiles/bigquery-profile).

#### 1. Fork the repo
Next, you will need to fork the package's repository. See steps 0-4 of [dbt's guide to editing external packages](https://discourse.getdbt.com/t/contributing-to-an-external-dbt-package/657) for how to do so.

#### 2. Update `unioning_multiple_destinations`
In your `dbt_project.yml` file, you must then add the `unioning_multiple_destinations` variable and set it to `true`. By default, the package assumes this to be `false`.

This step is necessary because the `unioning_multiple_destinations` boolean enables the package's `union_source_tables()` macro to run and aggregate data across destination databases.

```yml
# dbt_project.yml

...
config-version: 2

vars:
  fivetran_log:
    unioning_multiple_destinations: True
```

#### 3. Declare sources in `src_fivetran_log.yml`
Finally, you will need to define each destination as a separate source in `src_fivetran_log.yml`. The package already comes with:
1. A fully-defined source that runs on your target database and `fivetran_log` schema by default
2. A commented-out template to use for any subsequent sources

Due to the way that the Fivetran Log Connector dbt package unions data, you **must declare all tables in each source**. However, because each source's schema is indentical in table structure, you can use [yaml anchors](https://support.atlassian.com/bitbucket-cloud/docs/yaml-anchors/) to avoid duplicating this code. This way, you only need to explictly provide the table structure in the first source, which we have already written out (with table documentation and tests) in `src_fivetran_log.yml`. For any subsequent sources, you can simply point to the anchored table structure to incorporate these tables into the source.

See how to use yaml anchors in the example configuration of two sources below:

```yml
# src_fivetran_log.yml

...
version: 2

sources: 
    - name: fivetran_log_source_1
      database: source-1-database-name
      schema: fivetran_log

      loader: fivetran
      loaded_at_field: _fivetran_synced
      
      freshness:
        warn_after: {count: 72, period: hour}
        error_after: {count: 96, period: hour}

      tables: &fivetran_log_tables # declares the anchor
        - name: active_volume 
          description: ... 

    - name: fivetran_log_source_2
      database: source-2-database-name
      schema: fivetran_log

      loader: fivetran
      loaded_at_field: _fivetran_synced
      
      freshness:
        warn_after: {count: 72, period: hour}
        error_after: {count: 96, period: hour}

    tables: *fivetran_log_tables # points to the anchor and integrates its table structure

```


> Note: Declaring each source table is necessary due to how the `union_source_tables()` macro works. In each of the staging models, this macro will:
> 1. Iterate through the declared sources and their tables
> 2. Verify that the source's database has a relation matching the given `table_name`. This verification step is required because the `transformation` and `trigger_table` tables will only exist if you've created a transformation in that destination.
> 3. Union the matching tables
> 4. In the unioned table, store the record's source's *database* as `destination_database`

## Additional Configuration
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

## Contributions
Additional contributions to this package are very welcome! Please create issues
or open PRs against `master`. Check out 
[this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) 
on the best workflow for contributing to a package.

## Resources:
- Find all of Fivetran's pre-built dbt packages in our [dbt hub](https://hub.getdbt.com/fivetran/)
- Provide [feedback](https://www.surveymonkey.com/r/DQ7K7WW) on our existing dbt packages or what you'd like to see next
- Reach out to solutions@fivetran.com for any package assistance 
- Learn more about Fivetran [in the Fivetran docs](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the dbt docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the dbt blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
- Learn how to set up a Fivetran Log Connector [here](https://fivetran.com/docs/logs/fivetran-log/setup-guide)
