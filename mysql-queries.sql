--1. Create database and table in mysql
	CREATE DATABASE spacex; USE spacex;

CREATE TABLE spacex_missions (
Flight_Number VARCHAR(10),
Launch_Date VARCHAR(20),Launch_Time VARCHAR(10),Launch_Site VARCHAR(40),Vehicle_Type VARCHAR(50),
Payload_Name VARCHAR(50),Payload_Type VARCHAR(50),Payload_Mass_kg VARCHAR(15),Payload_Orbit VARCHAR(50),
Customer_Name VARCHAR(40),Customer_Type VARCHAR(40),Customer_Country VARCHAR(40),
Mission_Outcome VARCHAR(40),Failure_Reason VARCHAR(40),
Landing_Type VARCHAR(40),Landing_Outcome VARCHAR(40));

--2. Load data into the table
LOAD DATA INFILE '/home/cloudera/Desktop/ajinkya/datasets/spacex-missions/database.csv' 
INTO TABLE spacex_missions
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

--3. Create working table
	CREATE TABLE spacex_missions_w AS
SELECT Flight_Number, 
STR_TO_DATE(Concat(Launch_Date," ",Launch_Time),'%d %M %Y %H:%i') as Launch_DateTime, Launch_Site, Vehicle_Type, Payload_Name, Payload_Type, CAST(Payload_Mass_kg AS DECIMAL(10,3)) as Payload_Mass_kg, 
Payload_Orbit, Customer_Name, Customer_Type, Customer_Country, Mission_Outcome, Failure_Reason, Landing_Type, Landing_Outcome FROM spacex_missions

--4. Add timestamp and primarykey to the table
	ALTER TABLE spacex_missions_w
	ADD COLUMN pid INT(5) UNSIGNED PRIMARY KEY AUTO_INCREMENT;
  

--KNOWN BUG: If  Record_TS is not populated with current_timestamp and instead is populated with 
--'0000', truncate spacex_missions_w and write 

INSERT INTO spacex_missions_w
STR_TO_DATE(Concat(Launch_Date," ",Launch_Time),'%d %M %Y %H:%i') as Launch_DateTime,
Launch_Site, Vehicle_Type, Payload_Name, Payload_Type, 
CAST(Payload_Mass_kg AS DECIMAL(10,3)) as Payload_Mass_kg, 
Payload_Orbit, Customer_Name, Customer_Type, Customer_Country, 
Mission_Outcome, Failure_Reason, Landing_Type, Landing_Outcome,
00, CURRENT_TIMESTAMP FROM spacex_missions

--'spacex_missions_w'  is our working table in mysql; we will create its replica in hive.
--We will be constantly inserting and updating this table in mysql. After using four step 
--incremental approach, these changes will be reflected in Hive.
