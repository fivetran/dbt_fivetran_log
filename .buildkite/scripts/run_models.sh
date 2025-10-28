#!/bin/bash
set -euo pipefail

apt-get update
apt-get install libsasl2-dev

python3 -m venv venv
. venv/bin/activate
pip install --upgrade pip setuptools
if [ "$1" == "sqlserver" ]; then
    pip install -r integration_tests/requirements_sqlserver.txt

    curl -sSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft-prod.gpg
    curl -sSL https://packages.microsoft.com/config/debian/12/prod.list > /etc/apt/sources.list.d/mssql-release.list

    apt-get update
    ACCEPT_EULA=Y apt-get install -y msodbcsql18
    ACCEPT_EULA=Y apt-get install -y mssql-tools18
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
    source ~/.bashrc
    apt-get -y install unixodbc-dev
    apt-get update

    pip uninstall -y pyodbc
    pip install --no-cache-dir --no-binary :all: pyodbc==4.0.39

    # odbcinst -j

else
    pip install -r integration_tests/requirements.txt
fi
mkdir -p ~/.dbt
cp integration_tests/ci/sample.profiles.yml ~/.dbt/profiles.yml

db=$1
echo `pwd`
cd integration_tests
dbt deps
if [ "$db" = "databricks-sql" ]; then
dbt seed --vars '{fivetran_platform_schema: sqlw_tests_4}' --target "$db" --full-refresh
dbt compile --vars '{fivetran_platform_schema: sqlw_tests_4}' --target "$db" --full-refresh
dbt run --vars '{fivetran_platform_schema: sqlw_tests_4}' --target "$db" --full-refresh
dbt run --vars '{fivetran_platform_schema: sqlw_tests_4}' --target "$db"
dbt test --vars '{fivetran_platform_schema: sqlw_tests_4}' --target "$db"
dbt run --vars '{fivetran_platform_schema: sqlw_tests_4, fivetran_platform__usage_pricing: true, fivetran_platform_using_connection: false}' --target "$db" --full-refresh
dbt run --vars '{fivetran_platform_schema: sqlw_tests_4, fivetran_platform__usage_pricing: true, fivetran_platform_using_connection: false}' --target "$db"
dbt test --vars '{fivetran_platform_schema: sqlw_tests_4}' --target "$db"
dbt run --vars '{fivetran_platform_schema: sqlw_tests_4, fivetran_platform__credits_pricing: false, fivetran_platform__usage_pricing: true, fivetran_platform_using_transformations: true}' --target "$db" --full-refresh
dbt run --vars '{fivetran_platform_schema: sqlw_tests_4, fivetran_platform__credits_pricing: false, fivetran_platform__usage_pricing: true, fivetran_platform_using_transformations: true}' --target "$db"
dbt test --vars '{fivetran_platform_schema: sqlw_tests_4}'  --target "$db"
dbt run --vars '{fivetran_platform_schema: sqlw_tests_4, fivetran_platform__usage_pricing: false, fivetran_platform_using_destination_membership: false, fivetran_platform_using_user: false, fivetran_platform_using_transformations: false}' --target "$db" --full-refresh
dbt run --vars '{fivetran_platform_schema: sqlw_tests_4, fivetran_platform__usage_pricing: false, fivetran_platform_using_destination_membership: false, fivetran_platform_using_user: false, fivetran_platform_using_transformations: false}' --target "$db"
dbt test --vars '{fivetran_platform_schema: sqlw_tests_4}'  --target "$db"
else
dbt seed --target "$db" --full-refresh
dbt compile --target "$db" --full-refresh
dbt run --target "$db" --full-refresh
dbt run --target "$db"
dbt test --target "$db"
if [ "$db" = "bigquery" ]; then
dbt run --vars '{fivetran_platform_log_identifier: log_bq_json_data}' --target "$db" --full-refresh
dbt test --target "$db"
fi
dbt run --vars '{fivetran_platform__usage_pricing: true, fivetran_platform_using_connection: false}' --target "$db" --full-refresh
dbt run --vars '{fivetran_platform__usage_pricing: true, fivetran_platform_using_connection: false}' --target "$db"
dbt test --target "$db"
dbt run --vars '{fivetran_platform__credits_pricing: false, fivetran_platform__usage_pricing: true, fivetran_platform_using_transformations: true}' --target "$db" --full-refresh
dbt run --vars '{fivetran_platform__credits_pricing: false, fivetran_platform__usage_pricing: true, fivetran_platform_using_transformations: true}' --target "$db"
dbt test --target "$db"
dbt run --vars '{fivetran_platform__usage_pricing: false, fivetran_platform_using_destination_membership: false, fivetran_platform_using_user: false, fivetran_platform_using_transformations: false}' --target "$db" --full-refresh
dbt run --vars '{fivetran_platform__usage_pricing: false, fivetran_platform_using_destination_membership: false, fivetran_platform_using_user: false, fivetran_platform_using_transformations: false}' --target "$db"
dbt test --target "$db"
fi
if [ "$1" != "sqlserver" ]; then
dbt run-operation fivetran_utils.drop_schemas_automation --target "$db"
fi
