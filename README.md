# Fivetran Log 

This package models Fivetran Log data from [our free, internal connector](https://fivetran.com/docs/logs/fivetran-log). It uses **destination-level** data in the format described by [this ERD](https://docs.google.com/presentation/d/1lny-kFwJIvOCbKky3PEvEQas4oaHVVTahj3OTRONpu8/?usp=sharing) and reformats and unions the data to the **account level**.

This package enables you to better understand:
* how you are spending money in Fivetran according to our [consumption based pricing model](https://fivetran.com/docs/getting-started/consumption-based-pricing) at the table, connector, destination, and account levels
* how your data is flowing in Fivetran:
    * connector health and sync status
    * transformation run status

Thus, the package's main foci are to:
* union log data across different destinations, if given multiple warehouses
* create a history of measured monthly active rows (MAR) and credit consumption (and their relationship)
* enhance the connector table with sync metrics and relevant alert messages
* enhance the transformation table with run metrics

Note: this package is built to be compatible with BigQuery, Redshift, and Snowflake. 

## Models

| **model**                  | **description**                                                                                                                                               |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| fivetran\_log\_connenector\_status        | Each record represents a connector loading data into a destination, enriched with data about the connector's status and the status of its data flow.                                          |
| fivetran\_log\_transformation\_status     | Each record represents a transformation, enriched with data about the transformation's last sync and any tables whose new data triggers the transformation to run. |
| fivetran\_log\_mar\_table\_history     | Each record represents a table's active volume for a month, complete with data about its connector and destination.                             |
| fivetran\_log\_credit\_mar\_history    | Each record represents a destination's consumption, via its MAR, total credits used, and credits per millions MAR.                             |


## Installation Instructions
Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

## Configuration
Because the Fivetran Log connector exists at the *destination* level, you will need to declare each destination's log connector as a separate source in `src_fivetran_log.yml`.  

However, because each schema is identical in table structure, you can use [yaml anchors](https://support.atlassian.com/bitbucket-cloud/docs/yaml-anchors/) to avoid duplicating code. You'll need to provide the structure in the first source, which you can then point to in subsequent ones. See the example configuration of two sources below:

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
1. iterate through the declared sources and their tables
2. check if the source's database does indeed have a relation matching the given `table_name` (necessary because the `transformation` and `trigger_table` tables will only exist if you've created a transformation in that destination)
3. union the matching tables
4. in the unioned table, store the record's source's *database* as `destination_database`

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
- Learn how to set up a Fivetran Log connector [here](https://fivetran.com/docs/logs/fivetran-log/setup-guide)