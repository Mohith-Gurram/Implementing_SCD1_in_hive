#Shebang Statement
#!/bin/bash



mysql -uroot -p -e "create table project.project(custid integer(10) primary key not null,username varchar(30),quote_count varchar(30),ip varchar(30),entry_time varchar(30),prp_1 varchar(30),prp_2 varchar(30),prp_3 varchar(30),ms varchar(30),http_type varchar(30),purchase_category varchar(30),total_count varchar(30),purchase_sub_category varchar(30),http_info varchar(30),status_code integer(10),curr_time bigint);"

mysql --local-infile=1 -uroot -pWelcome@123 -e "set global local_infile=1;
load data local infile '/home/saif/LFS/cohort_f11/datasets/Day_1.csv' into table project.project fields terminated by ',';
update project.project set curr_time = CURRENT_TIMESTAMP() + 1 where curr_time IS NULL;
"

sqoop import --connect jdbc:mysql://localhost:3306/project?useSSL=False --username root --password Welcome@123 --query 'select custid,username,quote_count,ip,entry_time,prp_1,prp_2,prp_3,ms,http_type,purchase_category,total_count,purchase_sub_category,http_info,status_code,curr_time from project where $CONDITIONS' --split-by custid --target-dir /user/saif/HFS/Output/project;


hive -e "
create table project_hive.project_internal (
custid int,
username string,
quote_count string,
ip string,
entry_time string,
prp_1 string,
prp_2 string,
prp_3 string,
ms string,
http_type string,
purchase_category string,
total_count string,
purchase_sub_category string,
http_info string,
status_code int,
curr_time BIGINT
)
row format delimited fields terminated by ',';"

hive -e "load data inpath '/user/saif/HFS/Output/project' into table project_hive.project_internal;"


hive -e "create external table project_hive.project_intermediate_partition(
custid int,
username string,
quote_count string,
ip string,
prp_1 string,
prp_2 string,
prp_3 string,
ms string,
http_type string,
purchase_category string,
total_count string,
purchase_sub_category string,
http_info string,
status_code int,
curr_time BIGINT
)
partitioned by(year string,month string)
row format delimited fields terminated by ',';"

hive -e "set hive.exec.dynamic.partition=true;
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table project_hive.project_intermediate_partition partition (year, month) select custid,username,quote_count,ip,prp_1,prp_2,prp_3,ms,http_type,
purchase_category,total_count,purchase_sub_category,http_info,status_code,curr_time,
cast(year(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as year, 
cast(month(from_unixtime(unix_timestamp(entry_time , 'dd/MMM/yyyy'))) as string) as month from project_hive.project_internal;
create table project_hive.project_intermediate (
custid int,
username string,
quote_count string,
ip string,
entry_time string,
prp_1 string,
prp_2 string,
prp_3 string,
ms string,
http_type string,
purchase_category string,
total_count string,
purchase_sub_category string,
http_info string,
status_code int,
year string,
month string,
curr_time BIGINT
)
row format delimited fields terminated by ',';
insert into table project_hive.project_intermediate select * from project_hive.project_intermediate_partition t1 join (select max(curr_time) as max_date_time from project_hive.project_intermediate_partition) tt1 on tt1.max_date_time = t1.curr_time;"


mysql -uroot -p -e "create table project.project_sql_export (custid integer(10),username varchar(30),quote_count varchar(30),ip varchar(30),entry_time varchar(30),prp_1 varchar(30),prp_2 varchar(30),prp_3 varchar(30),ms varchar(30),http_type varchar(30),purchase_category varchar(30),total_count varchar(30),purchase_sub_category varchar(30),http_info varchar(30),status_code integer(10),year varchar(100),month varchar(100),curr_time bigint);"


sqoop export --connect jdbc:mysql://localhost:3306/project?useSSL=False --table project_sql_exp --username root --password Welcome@123 --export-dir "/user/hive/warehouse/project_hive.db/project_intermediate" --input-fields-terminated-by ',';
