#Shebang Statement
#!/bin/bash


mysql -uroot -p -e "
truncate table project.project;
truncate table project.project_sql_export;"

hive -e "truncate table project_hive.project_internal;"
hive -e "truncate table project_hive.project_intermediate;"

hdfs dfs -rm -r /user/saif/HFS/Output/project



mysql --local-infile=1 -uroot -p -e "set global local_infile=1;
load data local infile '/home/saif/LFS/cohort_f11/datasets/Day_$1.csv' into table project.project fields terminated by ',';
update project.project set curr_time = CURRENT_TIMESTAMP() + 1 where curr_time IS NULL;
"

sqoop import --connect jdbc:mysql://localhost:3306/project?useSSL=False --username root --password Welcome@123 --query 'select custid,username,quote_count,ip,entry_time,prp_1,prp_2,prp_3,ms,http_type,purchase_category,total_count,purchase_sub_category,http_info,status_code,curr_time from project where $CONDITIONS' --split-by custid --target-dir /user/saif/HFS/Output/project;



hive -e "load data inpath '/user/saif/HFS/Output/project' into table project_hive.project_internal;"


hive -e "set hive.exec.dynamic.partition=true;
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table project_hive.project_intermediate_partition partition (year, month) select a.custid,a.username,a.quote_count,a.ip,a.prp_1,a.prp_2,a.prp_3,a.ms,a.http_type,
a.purchase_category,a.total_count,a.purchase_sub_category,a.http_info,a.status_code,a.curr_time,
cast(year(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as year, 
cast(month(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as month from project_hive.project_internal a
join 
project_hive.project_intermediate_partition b
on a.custid=b.custid
union
select a.custid,a.username,a.quote_count,a.ip,a.prp_1,a.prp_2,a.prp_3,a.ms,a.http_type,
a.purchase_category,a.total_count,a.purchase_sub_category,a.http_info,a.status_code,a.curr_time,
cast(year(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as year, 
cast(month(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as month
from project_hive.project_internal a
left join 
project_hive.project_intermediate_partition b
on a.custid=b.custid
where b.custid is null
union
select b.custid,b.username,b.quote_count,b.ip,b.prp_1,b.prp_2,b.prp_3,b.ms,b.http_type,
b.purchase_category,b.total_count,b.purchase_sub_category,b.http_info,b.status_code,b.curr_time,
cast(year(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as year, 
cast(month(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as month
from project_hive.project_internal a
right join 
project_hive.project_intermediate_partition b
on a.custid=b.custid
where a.custid is null
;


insert into table project_hive.project_internal select * from project_hive.project_intermediate_partition t1 join (select max(curr_time) as max_date_time from project_hive.project_intermediate_partition) tt1 on tt1.max_date_time = t1.curr_time;"




sqoop export --connect jdbc:mysql://localhost:3306/project?useSSL=False --table project_sql_exp --username root --password Welcome@123 --export-dir "/user/hive/warehouse/project_hive.db/project_intermediate" --input-fields-terminated-by ',';

