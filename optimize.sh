#!/bin/sh

# Database connection parameters
DBHOST="localhost"
DBUSER="postgres"
DBNAME="resolvedb"

echo "optimizing $DBNAME database"

# Log file
LOG_FILE="optimize.log"

# Reindex the database
reindexdb --host $DBHOST --username $DBUSER $DBNAME --no-password --echo >> $LOG_FILE 2>&1

# Vacuum and analyze the database
vacuumdb --analyze --host $DBHOST --username $DBUSER $DBNAME --verbose --no-password >> $LOG_FILE 2>&1

# Check the exit codes to see if there were any errors
if [ $? -eq 0 ]; then
    echo "Database optimization successful. Check the log file for details: $LOG_FILE"
else
    echo "Database optimization failed. Check the log file for details: $LOG_FILE"
fi
