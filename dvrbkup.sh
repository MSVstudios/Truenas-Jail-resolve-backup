#!/bin/sh

# by MSV studios - 2017-2024
OUTDIR="/dvrbkup/"
# get date and time
mydate=$(date +%m_%d_%y-%H-%M)
# filenames
filename="$OUTDIR$mydate.sql"
filenamezip="$OUTDIR$mydate.sql.zip"
# store newest filename before generating a new one
lastfile=$(ls -t $OUTDIR*.zip 2>/dev/null | awk 'NR==1')

# Check if lastfile is empty before attempting to unzip
if [ -n "$lastfile" ]; then
    # uncompress last file
    unzip -d / "$lastfile"
    ls -l $OUTDIR
else
    echo "No previous backup file found for unzipping."
fi

# dump database
# C format -F c
pg_dump -U resolvedb resolvedb -F plain --blobs > $filename
echo "lastfile $filename ${lastfile%????}"

# compare last SQL dump 2 file: remove the last 4 chars (.zip) from lastfile name
if [ -n "$lastfile" ] && cmp -s "$filename" "${lastfile%????}"; then
    echo "the file has no difference with the previous pg_dump"
    echo "delete the file we just generated"
    # remove .sql files
    rm $OUTDIR*.sql
else
    echo "the files are different, zip the SQL dump"
    # zip .sql dump
    zip "$filenamezip" "$filename"
    # keep only the last 12 versions
    ls -t /backup/*.sql.zip 2>/dev/null | awk 'NR>12' | xargs rm -f
    # remove .sql files
    rm $OUTDIR*.sql
fi
