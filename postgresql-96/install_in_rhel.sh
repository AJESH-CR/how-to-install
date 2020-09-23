#!/bin/bash

RED="\033[1;31m"
RESET="\033[0m"

function fatalError() {
    echo -en "$(date +%F-%T)  ${RED}${*}${RESET}\n"
    exit 1
}

# Select PostgreSQL yum repository based on OS version and archeteture
    wget https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
    [ $? -ne 0 ] && fatalError "Failed to add PostgreSQL repo"
    # Install the EPEL repositories, which will be used to satisfy dependencies
    sudo yum install pgdg-redhat-repo-latest.noarch.rpm epel-release -y
    sudo yum update -y
    sudo yum install postgresql96-server postgresql96-contrib -y
    [ $? -ne 0 ] && fatalError "PostgreSQL 9.6 installation failed"
    # Initialize your database and start PostgreSQL
    sudo /usr/pgsql-9.6/bin/postgresql96-setup initdb
    sudo systemctl start postgresql-9.6
    sudo systemctl enable postgresql-9.6
    [ $? -ne 0 ] && fatalError "Failed to start postgresql-9.6 service"
    # Update Postgresql user postgres password
    sudo passwd postgres <<EOF
passwd
passwd
EOF
    # Edit /var/lib/pgsql/9.6/data/pg_hba.conf config file and
    # Add password authentication
    local PG_HBA=/var/lib/pgsql/9.6/data/pg_hba.conf
    su - postgres -c """
    cat > ${PG_HBA} <<EOF
    local   all             all                                     trust 
    host    all             all             127.0.0.1/32            trust
    host    all             all             ::1/128                 trust
EOF
    """ <<EOF
passwd
EOF
    [ $? -ne 0 ] && fatalError "Failed to update Postgresql ${PG_HBA} config file"
    # Restart the PostgreSQL service
    sudo service postgresql-9.6.service reload
    [ $? -ne 0 ] && fatalError "Failed to reload postgresql-9.6 service"
    sleep 30
    # Create PostgreSQL users and databases required for build & test
    local PSQL=$(which psql)
    cat > init.sql <<EOF
    -- Write your ddl statments here !.
EOF
    $PSQL postgres postgres -f init.sql
    [ $? -ne 0 ] && fatalError "Failed to initialize PostgreSQL database with roles and databases."
    rm -f init.sql pgdg-redhat-repo-latest.noarch.rpm
