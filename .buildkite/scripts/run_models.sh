#!/bin/bash
set -euo pipefail

apt-get update
apt-get install libsasl2-dev

python3 -m venv venv
. venv/bin/activate
pip install --upgrade pip setuptools
if [ "$1" == "sqlserver" ]; then
    pip install -r integration_tests/requirements_sqlserver.txt

    ## brew 
    # CI=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
    # eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    # brew update
    # brew install gcc
    # brew tap microsoft/mssql-release https://github.com/Microsoft/homebrew-mssql-release
    # HOMEBREW_ACCEPT_EULA=Y brew install msodbcsql18 mssql-tools18
    # brew install unixodbc

    ## debian 12
    curl https://packages.microsoft.com/keys/microsoft.asc | tee /etc/apt/trusted.gpg.d/microsoft.asc
    curl https://packages.microsoft.com/config/debian/12/prod.list | tee /etc/apt/sources.list.d/mssql-release.list
    apt-get update
    ACCEPT_EULA=Y apt-get install -y msodbcsql18
    ACCEPT_EULA=Y apt-get install -y mssql-tools18
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> ~/.bashrc
    source ~/.bashrc
    apt-get -y install unixodbc-dev
    apt-get update
    
    # works i think
    pip uninstall -y pyodbc
    pip install --no-cache-dir --no-binary :all: pyodbc==4.0.39
    
    # which odbcinst
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
dbt seed --target "$db" --full-refresh
dbt compile --target "$db"
dbt run --target "$db" --full-refresh
dbt run --target "$db"
dbt test --target "$db"
dbt run --vars '{fivetran_platform__usage_pricing: true}' --target "$db" --full-refresh
dbt run --vars '{fivetran_platform__usage_pricing: true}' --target "$db"
dbt test --target "$db"
dbt run --vars '{fivetran_platform__usage_pricing: false, fivetran_platform_using_destination_membership: false, fivetran_platform_using_user: false}' --target "$db" --full-refresh
dbt run --vars '{fivetran_platform__usage_pricing: false, fivetran_platform_using_destination_membership: false, fivetran_platform_using_user: false}' --target "$db"
dbt test --target "$db"
dbt run-operation fivetran_utils.drop_schemas_automation --target "$db"
