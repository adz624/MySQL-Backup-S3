#!/bin/sh

# Updates etc at: https://github.com/woxxy/MySQL-backup-to-Amazon-S3
# Under a MIT license

# change these variables to what you need
MYSQLROOT='backup'
MYSQLPASS=
S3BUCKET='visionbundles-backup'
FILENAME="Dev_DB"
DATABASE='--all-databases'
# the following line prefixes the backups with the defined directory. it must be blank or end with a /
S3PATH='mysql/'
# when running via cron, the PATHs MIGHT be different. If you have a custom/manual MYSQL install, you should set this manually like MYSQLDUMPPATH=/usr/local/mysql/bin/
MYSQLDUMPPATH=
#tmp path.
TMP_PATH=~/

DATESTAMP=$(date +"%Y-%m-%d-%Y")
DAY=$(date +"%d")
DAYOFWEEK=$(date +"%A")

PERIOD=${1-day}
if [ ${PERIOD} = "auto" ]; then
    if [ ${DAY} = "01" ]; then
            PERIOD=month
    elif [ ${DAYOFWEEK} = "Sunday" ]; then
            PERIOD=week
    else
            PERIOD=day
    fi  
fi

echo "Selected period: $PERIOD."

echo "Starting backing up the database to a file..."

# dump all databases
${MYSQLDUMPPATH}mysqldump --quick --user=${MYSQLROOT} --password=${MYSQLPASS} ${DATABASE} > ${TMP_PATH}${FILENAME}.sql

echo "Done backing up the database to a file."
echo "Starting compression..."

tar czf ${TMP_PATH}${FILENAME}_${DATESTAMP}.tar.gz ${TMP_PATH}${FILENAME}.sql

# upload all databases
echo "Uploading the new backup..."
s3cmd put -f ${TMP_PATH}${FILENAME}_${DATESTAMP}.tar.gz s3://${S3BUCKET}/${S3PATH}
echo "New backup uploaded."

echo "Removing the cache files..."
# remove databases dump
rm ${TMP_PATH}${FILENAME}.sql
rm ${TMP_PATH}${FILENAME}_${DATESTAMP}.tar.gz
echo "Files removed."
echo "All done."
