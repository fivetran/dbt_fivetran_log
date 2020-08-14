# Fivetran Log 

This package models Fivetran Log data from [our free internal connector](https://fivetran.com/docs/logs/fivetran-log). It uses **destination-level** data in the format described by [this ERD](https://docs.google.com/presentation/d/1lny-kFwJIvOCbKky3PEvEQas4oaHVVTahj3OTRONpu8/?usp=sharing) and unions the data to the **account level**.

> Note: The Fivetran Log Connector dbt package is compatible with BigQuery, Redshift, and Snowflake.
> Though compatible with each individual kind of warehouse, the package is not *cross-compatible*. For example, you can union log data across various BigQuery destinations, but not BigQuery *and* Snowflake destinations.

This package helps you understand:
* How you are spending money in Fivetran according to our [consumption-based pricing model](https://fivetran.com/docs/getting-started/consumption-based-pricing). We display consumption data at the table, connector, destination, and account levels.
* How your data is flowing in Fivetran:
    * Connector health and sync statuses
    * Transformation run statuses

The package's main goals are to:
* Union log data across destinations
* Create a history of measured monthly active rows (MAR), credit consumption, and the relationship between the two
* Enhance the connector table with sync metrics and relevant alert messages
* Enhance the transformation table with run metrics

## Models

| **model**                  | **description**                                                                                                                                               |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| fivetran\_log\_connector\_status        | Each record represents a connector loading data into a destination, enriched with data about the connector's status and the status of its data flow.                                          |
| fivetran\_log\_transformation\_status     | Each record represents a transformation, enriched with data about the transformation's last sync and any tables whose new data triggers the transformation to run. |
| fivetran\_log\_mar\_table\_history     | Each record represents a table's active volume for a month, complete with data about its connector and destination.                             |
| fivetran\_log\_credit\_mar\_history    | Each record represents a destination's consumption by showing its MAR, total credits used, and credits per millions MAR.                             |


## Installation Instructions
Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

## Configuration
### Accessing your destinations
First, you'll need to ensure that dbt can access your destination(s) by providing the appropriate credentials in your `~/.dbt/profiles.yml` file. Different destinations may require different profile setups. Learn how to set up your destination's profile in [dbt's supported databases documentation](https://docs.getdbt.com/docs/supported-databases). 

> Note: If you are using multiple BigQuery databases, you must use the OAuth authentication method instead of service accounts. Both methods are included in [dbt's BigQuery profile documentation](https://docs.getdbt.com/reference/warehouse-profiles/bigquery-profile).

### Using a single destination 
If you are only looking at data from one destination, you only need to declare one source in `src_fivetran_log.yml`. 

We've included a largely complete template of a source, in which you only need to input the source `database` and `schema`. This source template includes freshness tests and table declarations, complete with descriptions and tests. You **must** include these table declarations in your source for the package to function.

### Using multiple destinations 
Because the Fivetran Log Connector exists at the *destination* level, you need to declare each destination's log connector as a separate source in `src_fivetran_log.yml`. 

Because of the way the Fivetran Log Connector dbt package unions data, you **must declare all tables in each source**. However, because each source's schema is indentical in table structure, you can use [yaml anchors](https://support.atlassian.com/bitbucket-cloud/docs/yaml-anchors/) to avoid duplicating this code. This way, you only need to provide the table structure in the first source, which we have already written out (with table documentation and tests) in `src_fivetran_log.yml`. For any subsequent sources, you can simply point to the anchored table structure.

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

      tables: &fivetran_log_tables # declaring the anchor
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

    tables: *fivetran_log_tables # points to the anchor

```

Then, in each of the staging models, the `union_source_tables(table_name)` macro will:
1. Iterate through the declared sources and their tables
2. Verify that the source's database has a relation matching the given `table_name`. This verification step is necessary because the `transformation` and `trigger_table` tables will only exist if you've created a transformation in that destination.
3. Union the matching tables
4. In the unioned table, store the record's source's *database* as `destination_database`

## Contributions

Additional contributions to this package are very welcome! Please create issues
or open PRs against `master`. Check out 
[this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) 
on the best workflow for contributing to a package.

## Resources:
- Provide [feedback](https://www.surveymonkey.com/r/DQ7K7WW) on our existing dbt packages or what you'd like to see next
- Learn more about Fivetran [in the Fivetran docs](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the dbt docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the dbt blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices
- Learn how to set up a Fivetran Log Connector [here](https://fivetran.com/docs/logs/fivetran-log/setup-guide)
