#!/bin/bash

set -euo pipefail

apt-get update
apt-get install libsasl2-dev

python3 -m venv venv
. venv/bin/activate
pip install --upgrade pip setuptools
pip install -r integration_tests/requirements.txt
mkdir -p ~/.dbt
cp integration_tests/ci/sample.profiles.yml ~/.dbt/profiles.yml

db=$1
echo `pwd`
cd integration_tests
dbt deps
dbt seed --target "$db" --full-refresh
dbt run --target "$db" --full-refresh
dbt test --target "$db"
dbt run --vars '{fivetran_log__usage_pricing: true}' --target "$db" --full-refresh
dbt test --target "$db"
dbt run --vars '{fivetran_log__usage_pricing: false, fivetran_log_using_account_membership: false, fivetran_log_using_destination_membership: false, fivetran_log_using_user: false}' --target "$db" --full-refresh
dbt test --target "$db"