# Fivetran Log 

This package models Fivetran Log data from [Fivetran's free, internal connector](https://fivetran.com/docs/logs/fivetran-log). It uses data in the format described by [this ERD](https://docs.google.com/presentation/d/1lny-kFwJIvOCbKky3PEvEQas4oaHVVTahj3OTRONpu8/?usp=sharing).

Read more about monthly active rows [here](https://fivetran.com/blog/consumption-based-pricing).

# continue here

This package enables you to better understand your GitHub issues and pull requests.  Its main focus is to enhance these two core objects with commonly used metrics. Additionally, the metrics tables let you better understand your team's velocity over time.  These metrics are available on a daily, weekly, monthly and quarterly level.

## Models

This package contains transformation models, designed to work simultaneously with our [GitHub source package](https://github.com/fivetran/dbt_github_source). A dependency on the source package is declared in this package's `packages.yml` file, so it will automatically download when you run `dbt deps`. The primary outputs of this package are described below. Intermediate models are used to create these output models.

| **model**                  | **description**                                                                                                                                               |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| github\_issues             | Each record represents a GitHub issue, enriched with data about its assignees, milestones, and time comparisons.                                             |
| github\_pull\_requests     | Each record represents a GitHub pull request, enriched with data about its repository, reviewers, and durations between review requests, merges and reviews. |
| github\_daily\_metrics     | Each record represents a single day, enriched with metrics about PRs and issues that were created and closed during that period.                              |
| github\_weekly\_metrics    | Each record represents a single week, enriched with metrics about PRs and issues that were created and closed during that period.                             |
| github\_monthly\_metrics   | Each record represents a single month, enriched with metrics about PRs and issues that were created and closed during that period.                            |
| github\_quarterly\_metrics | Each record represents a single quarter, enriched with metrics about PRs and issues that were created and closed during that period.                          |


## Installation Instructions
Check [dbt Hub](https://hub.getdbt.com/) for the latest installation instructions, or [read the dbt docs](https://docs.getdbt.com/docs/package-management) for more information on installing packages.

## Configuration
By default, this package will look for your GitHub data in the `github` schema of your [target database](https://docs.getdbt.com/docs/running-a-dbt-project/using-the-command-line-interface/configure-your-profile). If this is not where your GitHub data is (perhaps your GitHub schema is `github_fivetran`), add the following configuration to your `dbt_project.yml` file:

```yml
# dbt_project.yml

...
config-version: 2

vars:
  github_source:
    github_database: your_database_name
    github_schema: your_schema_name 
```

## Contributions

Additional contributions to this package are very welcome! Please create issues
or open PRs against `master`. Check out 
[this post](https://discourse.getdbt.com/t/contributing-to-a-dbt-package/657) 
on the best workflow for contributing to a package.

## Resources:
- Learn more about Fivetran [in the Fivetran docs](https://fivetran.com/docs)
- Check out [Fivetran's blog](https://fivetran.com/blog)
- Learn more about dbt [in the dbt docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](http://slack.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the dbt blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices