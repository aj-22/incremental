1) Shell Action
		Execute IMPALA query and echo the output

			if [ "$(whoami)" = "yarn" ]; then
			 export USER=yarn
			 export PYTHON_EGG_CACHE=/tmp/impala-shell-python-egg-cache-${USER}
			fi

			Q0=$(impala-shell -i "localhost" -q "invalidate metadata;" )
			echo "$Q0"

			QUERY=$(impala-shell -i "localhost" -q "select max(record_ts) from spacex.missions_base;") 
			Q1=`echo "$QUERY" | egrep -o "[0-9][0-9][0-9][0-9]-[0-2][0-9]-[0-3][0-9] [0-2][0-9]:[0-6][0-9]:[0-9][0-9]"`
			echo "MAXTS=$Q1"

		Explanation of script:
			We are setting environment variables to yarn because OOZIE executes its actions as YARN and not as CLOUDERA. There may be a conflict between whoami and  $USER.

			[cloudera@quickstart ~]$ sudo -u yarn whoami
			yarn
			[cloudera@quickstart ~]$ whoami
			cloudera
			[cloudera@quickstart ~]$ sudo -u yarn echo $USER
			cloudera
			[cloudera@quickstart ~]$ echo $USER
			cloudera

		Secondly, we need to set up PYTHON_EGG_CACHE as Impala is written in Python and might need a temporary cache directory.

		Possible enhancement: invalidate metadata might be replaced by refresh as refresh is less resource consuming and faster.

		Query output:
		+-----------------------+
		| max(record_ts)        |
		+-----------------------+
		| 2017-04-07 03:14:29.0 |
		+-----------------------+
		Therefore we use a regex expression to extract timestamp. 
		And echo the output as 
		MAXTS=2017-04-07 03:14:29.0

2) SQOOP Action

All the options will have to be entered as argument in Sqoop action

		import
		--connect
		jdbc:mysql://quickstart.cloudera:3306/spacex
		--username
		root
		--password
		cloudera
		--table
		spacex_missions_w
		-m
		1
		--check-column
		Record_TS
		--incremental
		lastmodified
		--last-value
		${wf:actionData("shell-1860")["MAXTS"]}
		--merge-key
		pid
		--split-by
		pid
		--target-dir
		/user/cloudera/hive/external/missions_inc

	Files selected under SQOOP action
		/user/cloudera/jars/mysql-connector-java-5.1.34-bin.jar
		/user/cloudera/hive/hive-site.xml


It must be noted that create-hive-table doesn't work with OOZIE. However, hive-import may work and we can use this facility. However, here we have uploaded data into HDFS and we will create an external table on top of it. Specifying, --merge-key primary_key is required so as to execute incremental update the second time. (Meaning first incremental update may work without specifying merge-key). Everything else is same as SQOOP command mentioned in Hortonworks 4 Steps Incrmental Guide. https://hortonworks.com/blog/four-step-strategy-incremental-updates-hive/

3) HIVE Action to create incremental table

		create external table spacex.missions_inc (
				flight_number	string,
				launch_datetime	string,	
			launch_site	string,	
			vehicle_type	string,
			payload_name	string,	
			payload_type	string,	
			payload_mass_kg	double,	
			payload_orbit	string,	
			customer_name	string,	
			customer_type	string,	
			customer_country	string,	
			mission_outcome	string,
			failure_reason	string,	
			landing_type	string,	
			landing_outcome	string,	
			pid	bigint,	
			record_ts	string)
		ROW FORMAT delimited
		FIELDS TERMINATED BY ','
		STORED AS TEXTFILE
		LOCATION '/user/cloudera/hive/external/missions_inc/';

4) HIVE Action to reconcile and purge

		--RECONCILE AND PURGE HIVE TABLES
		DROP TABLE IF EXISTS spacex.missions_reporting;
		CREATE TABLE spacex.missions_reporting AS
		SELECT * FROM spacex.missions_reconcile_view;
		DROP TABLE IF EXISTS spacex.missions_inc;
		--DROP TABLE IF EXISTS spacex.missions_base;
		--CREATE TABLE spacex.missions_base LIKE spacex.missions_reporting;
		INSERT OVERWRITE TABLE spacex.missions_base SELECT * FROM spacex.missions_reporting;	

		Instead of deleting Base table, it might be a good idea to overwrite it.

5) HDFS Action
		Refer Image wf2-HDFS Action

Possible Enhancement: All the hive actions mentioned above can be executed in IMPALA and performance can be improved especially those which involve JOINS
