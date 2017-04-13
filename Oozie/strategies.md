This document reflects two strategies that can be used to execute Incremental updates in HIVE by desgining a workflow in OOZIE.
1) Using SQOOP metastore
	When SQOOPing updated data from saved job into HIVE, it was observed that SQOOP automatically updated timestamp parameter for  --last-value for next incremental import. 
Now we may ask this question where does SQOOP store this timestamp?
The answer to this question is sqoop metastore. A particular SQOOP job is stored on a metastore of a particular node. There is a difference between invoking SQOOP command via CLI on an edgenode and invoking SQOOP via OOZIE. OOZIE may invoke SQOOP commands on any node and not necessarily on the node which has SQOOP job and metastore saved. This problem can be tackled by using --meta-store option in SQOOP command. This sets a single meta-store to be used for OOZIE. Additional research may be needed.

2)  Calculating latest timestamp using Hive Query
	In this strategy, before SQOOPing data, we calculate the latest timestamp of base_table in HIVE using SELECT MAX() query. The output is echoed in shell. And by using capture-output facility of OOZIE we directly pass this value into --last-value of SQOOP command. We will be using this strategy in this document.
