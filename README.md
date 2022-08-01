This is the project which is based on the concept of Hadoop, Sqoop, Hive,Sql and Shell Scripting. In this project, SCD-1 logic is implemented using shell scripting, hive and Sqoop.

Pictorial Presentation of Project
![PRJ](https://user-images.githubusercontent.com/107995926/175781084-30b27f94-104b-4ca9-945c-ee7ddce15bbb.jpeg)



Description

In this project Data is sent by the client everyday in CSV format. So load all the data in MySQL everyday and then export it to HDFS. From there load the Data to hive
and do the partioning on Year and Month and implement SCD Type-1 Logic and then load the data for Data reconcilation so that no loss of data takes place at any day.




About SCD Type-1

SCD Stands for Slowly changing dimensions.

SCD type 1 methodology is used when there is no need to store historical data in the dimension table.

This method overwrites the old data in the dimension table with the new data. It is used to correct data errors in the dimension.



Approach

1.First I transfer all the datasets to Virtual machine on my system using WinSCP.

2.After getting Datasets on EdgeNode, put all datasets in a Archive folder as a BackUp purpose.

3.Then export Day1 data to SQL database in a table(dummy_data), also added one column for comaparing updated timestamp.

4.From RDBMS, I export the Day1 data to HDFS using sqoop.

5.After that created a table in Hive and loaded data(Day1) into it from HDFS.

6.Then, created a External table and loaded data from Managed table to it and
done partitioning on the basis of Year and then on the basis of Months.

7.Then implemented SCD Type-1 logic using SQL query with the concept of Join and Union.

8.Again created one intermediate table in hive, and inserted all data from external table to this and implemented SQL query for getting updated values only for successfull implementation of SCD Type-1 for further Data coming next days.

9.Then created a table in SQL and export all records from intermediate to it using sqoop for Data Reconciliation.




This all methods are written using shell scripting so that Automation is possible and no manual intervation required everytime.

