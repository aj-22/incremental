-- 9. Check data in hive
-- In hive we have two tables missions_base which contains 
-- original data and missions_inc which contains updated data. 

-- 10. Reconcile View
-- This view combines record sets from both the Base (base_table) and 
-- Change (incremental_table) tables and is reduced only to the most recent records for each unique “id”. 
-- Create reconcile view of missions_base and missions_inc

CREATE VIEW missions_reconcile_view AS
SELECT t1.* FROM
    (SELECT * FROM missions_base
     UNION ALL
     SELECT * from missions_inc) t1
JOIN
    (SELECT pid, max(record_ts) max_ts FROM
        (SELECT * FROM missions_base
         UNION ALL
         SELECT * from missions_inc) t_temp
     GROUP BY pid) t2
ON t1.pid = t2.pid AND t1.record_ts = t2.max_ts;

-- 11. Compaction of Data
-- The reconcile_view now contains the most up-to-date set of records 
-- and is now synchronized with changes from the RDBMS source system. Before creating this table, any previous instances of the table should be dropped as in the example below. 

DROP TABLE IF EXISTS missions_reporting;
CREATE TABLE missions_reporting AS
SELECT * FROM missions_reconcile_view;

-- 12. Purging incremental table data and reloading data into base table
DROP TABLE IF EXISTS missions_inc;
!sudo hdfs fs –rm –r /user/hive/warehouse/spacex.db/missions_inc
DROP TABLE missions_base;
CREATE TABLE missions_base LIKE missions_reporting
INSERT OVERWRITE TABLE missions_base SELECT * FROM missions_reporting;
