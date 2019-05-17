#!/bin/bash

# Be verbose, and stop with error as soon there's one
set -ev


pip install virtualenv
virtualenv ~/env
source ~/env/bin/activate
pip install transifex-client sphinx-intl
pip install ".[docs,testing]"

# Create the main database
TEST_AIIDA_BACKEND="django"
PSQL_COMMAND="CREATE DATABASE $TEST_AIIDA_BACKEND ENCODING \"UTF8\" LC_COLLATE=\"en_US.UTF-8\" LC_CTYPE=\"en_US.UTF-8\" TEMPLATE=template0;"
psql -h localhost -c "${PSQL_COMMAND}" -U postgres -w
# Setup the main profile
verdi setup --profile $TEST_AIIDA_BACKEND \
    --email="aiida@localhost" --first-name=AiiDA --last-name=test --institution="AiiDA Team" --password 'secret' \
    --db-engine 'postgresql_psycopg2' --db-backend=$TEST_AIIDA_BACKEND --db-host="localhost" --db-port=5432 \
    --db-name="$TEST_AIIDA_BACKEND" --db-username=postgres --db-password='' \
    --repository="/tmp/repository_${TEST_AIIDA_BACKEND}/" --non-interactive

# Set the main profile as the default
verdi profile setdefault $TEST_AIIDA_BACKEND

# Set the polling interval to 0 otherwise the tests take too long
verdi config runner.poll.interval 0

# Generate pot file and upload to transifex platform
TRANSIFEX_PROJECT_NAME="aiida-zh_cn"
sphinx-build -b gettext docs/source locale
tx init --no-interactive
sphinx-intl update-txconfig-resources --pot-dir locale --transifex-project-name ${TRANSIFEX_PROJECT_NAME}
sudo echo $'[https://www.transifex.com]\nhostname = https://www.transifex.com\nusername = '"$TRANSIFEX_USER"$'\npassword = '"$TRANSIFEX_PASSWORD"$'\ntoken = '"$TRANSIFEX_API_TOKEN"$'\n' > ~/.transifexrc
tx push -s
