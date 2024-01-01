
# Truenas-Jail-resolve-backup
Truenas Jail resolve backup

Our studio has been utilizing this robust solution since 2019, and it has consistently delivered reliable performance without any issues.

### Features:

1.  **Remote Database Access:**
    
    -   Editors can securely access the Davinci Resolve database through our VPN (WireGuard), ensuring seamless collaboration from anywhere.
2.  **Regular Backups:**
    
    -   SQL dumps are automatically executed and uploaded to a cloud storage every 6 hours, providing a comprehensive backup strategy.
3.  **Quick Recovery:**
    
    -   In the unfortunate event of a server failure, our system is designed to recover the database in less than 5 minutes, ensuring minimal downtime. This recovery capability extends globally, allowing for swift restoration from any location worldwide.

> NB: In our production installation we have 2 separate jails with  PostgreSQL: a Master and a Replica.
>  DaVinci Resolve is Connected to the Master and the Dump is executed on the Replica.
>  This is to avoid an an Hang when the Db make a backup

## **Install PostgreSQL into a jail in TrueNAS CORE for Blackmagic Design Davinci Resolve database**


### **Why TrueNAS CORE?**


* FreeBSD
* ZFS (one billion$) file system 
    * checksum
    * snapshot 
* Jail
* Easy to manage
Integrated with existing storage server (TrueNAS core)


NB: We will use PostgreSQL v 11.21 instead the recommended  9.5.3 by BMD, for compatibility reason on FreeBSD \


**We highly suggest to use a thick jail and not a tiny jail** 

 - tiny jail: 	use less storage 	
 - thick jail: 	can be easily moved to another server with zfs send and zfs receive independent os update inside the jail

**IF YOU DON'T NEED A THICK JAIL** you can use TrueNAS GUI to create a jail and set up the IP address \
 
You can use the TrueNAS GUI shell or log with ssh on your TrueNAS instal

NB: to paste TrueNAS  core GUI shell: shift + ins


**list the RELEASE and fetch the release 13.2-RELEASE**

```
root@truenas:~ # iocage fetch
```


**Create a thick jail**

```
root@truenas:~ # iocage create -r 13.2-RELEASE --thickjail --name resolvepgsql
```


You may get a error, if you have old FreeNAS/TrueNAS upgraded install but you can ignore it:

Default mac_prefix specified in defaults.json '70106f' is invalid. Using '72106f' mac prefix instead. \
[https://www.truenas.com/community/threads/cannot-create-jail-v11-3-u3-2-u3.85702/#post-593364](https://www.truenas.com/community/threads/cannot-create-jail-v11-3-u3-2-u3.85702/#post-593364) \
 

We will use *resolvepgsql* as jail name but you can use what you want

 

#### **Set up the jail IP ADDRESS**

```
root@truenas:~ # iocage set dhcp=1 vnet=1 bpf=1 resolvepgsql
# or a fix ip addr
root@truenas:~ # iocage set ip4_addr="192.168.10.100/24" vnet=1 bpf=1 resolvepgsql
```

Set the IP address accordingly to your network setup \


### **Check if the jail as been created and the IP address is set up correctly**


```
root@truenas:~ # iocage list
```


### **Start and Login on the jail console**


```
root@truenas:~ # iocage start resolvepgsql
root@truenas:~ # iocage console resolvepgsql
```


## Be Careful your are root/sudo on the jail now

```
root@resolvepgsql:~ # pkg update
```


Prompt will ask to install package management tool, answer **Y \

Install nano**
```
root@resolvepgsql:~ # pkg install nano
```

But you can use **_vi_** if you prefer 


**Install postgresql 11.21**


```
root@resolvepgsql:~ # pkg install postgresql11-server-11.21
```


 \
**Enable postgresql**


```
root@resolvepgsql:~ # nano -c /etc/rc.conf
```


Add at the end of the file 


```
#enable postgreSQL
postgresql_enable="YES"
```


**Ctrl O** then Enter to save,  **Ctrl X** then Enter to exit nano \


**Initialize the database db**


```
root@resolvepgsql:~ # /usr/local/etc/rc.d/postgresql initdb
```


**Check if _postgres _user exist**


```
root@resolvepgsql:~ #  cat /etc/passwd
......
postgres:*:770:770:PostgreSQL Daemon:/var/db/postgres:/bin/sh
```

You must see the *postgres* user at the bottom of the user list\
 
**Find the postgres directory accordingly to what found an the previous step**
```
root@resolvepgsql:~ # find / -name postgresql.conf
/var/db/postgres/data11/postgresql.conf
root@resolvepgsql:~ # find / -name pg_hba.conf
/var/db/postgres/data11/pg_hba.conf
```
in the example above the PostgreSQL install is at: **/var/db/postgres/data11**

**Start postgreSQL server** 

change your postgres install accrodly to 
```
root@resolvepgsql:~ # su - postgres
$ /usr/local/bin/pg_ctl -D /var/db/postgres/data11 -l logfile start
$ /usr/local/bin/pg_ctl -D /var/db/postgres/data11 -l logfile status
```

**Exit from postgres user**

```
$ exit
```

**Add pw to postgres user** 


```
root@resolvepgsql:~ # passwd postgres
```

**Login on postgres user**
```
root@resolvepgsql:~ # su - postgres
$
```

 **Backup your pg_hba.conf**

```
$ cp /var/db/postgres/data11/pg_hba.conf /var/db/postgres/data11/pg_hba.conf.backup
```

**Edit pg_hba.conf**
```
$ nano -c /var/db/postgres/data11/pg_hba.conf
```




**Add at the end of the file for each one of the workstations that need to access to the postgreSQL database**

**Example:**
```
host     all     all     192.168.10.10/24     md5 
host     all     all     192.168.10.11/24     md5
host     all     all     192.168.10.12/24     md5
host     all     all     192.168.10.50/24     md5
host     all     all     192.168.10.51/24     md5
host     all     all     192.168.10.52/24     md5
# add more if need or you can add network mask for a IP address range  in CIDR format
```
NB: md5 at the end is for password log


**Enable out connections**
```
$ nano -c /var/db/postgres/data11/postgresql.conf
```
\


### IMPORTANT

> **For testing allow all connection but for production specify the net mask or a single address that are allowed to connect to your database
> in the network**

```
listen_addresses = '*'
# to test, unsecure. Replace with single ip address  or a ip range for better security
```

\
**Exit the postgres user **

```
$ exit
```

\
**Restart postgreSQL**


```
root@resolvepgsql:~ # service postgresql restart
```


 \
**Check port connections**


```
root@resolvepgsql:~ # sockstat -4 -6 | grep 5432
pgsql    postgres   10912 3  tcp4   <YOUR JAIL IP ADDR>:5432  *:*
```


NB: *The first number can be different on your system*

 \
**Re enter in shell with the  postgres user**


```
root@resolvepgsql:~ # su - postgres
$
```


**Create new DB user**

```
$ createuser -sdrP resolvedb
```
NB: *You can also create the user in the postgres console if you prefer*

> If security is important for you **don't**  use ***DaVinci*** password

 \
**Create new Db for the newly created user**


```
$ createdb -U resolvedb -E UTF8 -O resolvedb -e resolvedb
# createdb -U your_username -E UTF8 -O your_username -e your_database_name
```

> If you need change password or you have trouble
```
$ psql resolvedb
resolvedb=# \password # to change passwd
resolvedb=# \q # to exit psql prompt
```

\
**Exit from postgres user**
```
$ exit
```

**Restart postgreSQL**
```
root@resolvepgsql:~ # service postgresql restart
```


**Exit jail console**
```
root@resolvepgsql:~ # exit
root@rtruenas:~ #
```
------------------------------------------------

### Connect to the new db in resolve 
on project manager -> Network -> Add Project Library
on the popup  enter your IP address, the username (resolvedb in these instructions) and your password
 
Try to import a big project to the database using the project manager and try to save and check  if you encounter any error. \

### Attention/Remember
    This is not a secure network installation, if the security of your data is a concern you must harden the network management. This is out of the scope of this explainer.

Remember to set up a recurring *snapshot* of your jail and also if you want a database dump. \
Furthermore you can Make a *cron* script with something similar to this

### example on how to dump your Database
```
# dump into file in text sql format (you can only restore with psql)
pg_dump -U resolvedb resolvedb -F plain --blobs > /backup/resolveDBbackup.sql
# dump into file in postgres c sql format (you can resotore with pgadmin-> restore)
pg_dump -U resolvedb resolvedb -F c --blobs > /backup/resolveDBbackup.sqlc
```




## **script example that you can launch with cron**
```
cd ~
mkdir scripts
touch scripts/dvrbkup.sh
nano scripts/dvrbkup.sh
```
```
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
```

**make it executable**
```
chmod +x scripts/dvrbkup.sh
```

**execute**
```
./scripts/dvrbkup.sh
````

### make a cron in TrueNAS
in Tasks -> Cron Jobs -> ADD

in the Commnad filed
```
iocage exec resolvepgsql sh /scripts/dvrbkup.sh
```

Run As User: *root*
set your Schedule as you want.



## **RESTORE a dump**

**Rename the db if you need it**
```
# \connect to postgres db

db=

# terminate all connection to the db

SELECT
    pg_terminate_backend (pid)
FROM
    pg_stat_activity
WHERE
    datname = 'resolvedb';


# rename
ALTER DATABASE resolvedb RENAME TO resolvedbold ;
```


**Recreate a new fresh db (UTF8)**


```
psql
CREATE DATABASE your_database_name WITH OWNER = your_username ENCODING = 'UTF8';
```
or
```
createdb -U resolvedb -E UTF8 -O resolvedb -e resolvedb
# createdb -U your_username -E UTF8 -O your_username -e your_database_name
```

**Restore the dump with psql**

```
# restore a dump
# psql -U username -f backupfile.sql
psql -U resolvedb -f backupfile.sql
```


### **Useful postgres command**

**Enter postgrees console**

```
psql
```

**List db**
```
\l
```
**List users**
```
\du
```

**Exit postgree console**
```
\q
```

