# 6. Replica of mysql table in hive
sqoop import \
--connect jdbc:mysql://10.170.245.155:3306/spacex \
--driver com.mysql.jdbc.Driver \
--username root \
--password cloudera \
--table spacex_missions_w \
--hive-import --create-hive-table \
--hive-table spacex.missions_base -m 1

# In case we encounter '0000-00-00 00:00:00' values in timestamp column then we can use 
# jdbc:mysql://10.170.245.155:3306/spacex?zeroDateTimeBehavior=convertToNull
# to convert into to null

# 7. Update mysql data
# Now we make changes in mysql table worldbase and load only the updated data 
# into hive using sqoop incremental option.
# example : 	UPDATE spacex_missions_w SET customer_name='NA' WHERE pid=2023, pid=2025;

# 8. Create incremental table
# In order to support an on-going reconciliation between current records in HIVE 
# and new change records, two tables should be defined: missions_base and missions_inc

sqoop job \
--create spacex_import_job -- import \
--connect jdbc:mysql://quickstart.cloudera:3306/spacex \
--driver com.mysql.jdbc.Driver --username root \
--password cloudera --table spacex_missions_w \
--hive-import --create-hive-table --hive-table spacex.missions_inc -m 1 \
--check-column Record_TS --incremental lastmodified \
--last-value "2017-03-22 03:40:00"

sqoop job --exec spacex_import_job
	
#	We don't need to reset last-value while running the job next time 
# as sqoop implicitly sets it.
