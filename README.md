# UNICEF-Children-Database-
Final project of Advanced Database.

## Description
In this project, we would like to track the education information in each country, including the school completion rate, out of school rate for primary education. In particular, we would like to identify if a country is listed as least developed countries (LDC). Similarly, we also want to obtain information of child labor rates in each country, and also the labor population of males and females. We would also like to identify the violence situation in each country and see the specific numbers on males and females.

##  Operational Database
The raw datasets on the websites are distributed various modules under different subjects. To get an overview of these data, the data from 5 modules were deployed in our project: Pre-primary education data, child labor data, violence data and child education data. Details of the database can be found in "ChildrenDatabase.sql".

##  Dimension Model
In the dimension model, the fact education would like to measure the total violence number, population in urban areas, population in rural areas, total labor number in each country, and also get the education rates from the operational education table related to primary information. Based on the requirements, we have four dimensions. 

##  ETL and SSIS package
Based on the dimension model above, the ETL process was successfully built in our project including appropriate constraints. The SCD levels for the dimension models in our project was set to 1 as we do not need to track the date information of the data. In order to seek records in dimension tables, and then to see their corresponding records in the related fact table, appropriate indexes were also built to ensure the work is optimized. Details of the building process can be found in the submitted “DM_ETL.sql”.

##  Multidimension cube using SSAS
By looking at the measures in the fact table, we can Calculate mean, median and rank the member of the country hierarchy based on school completion rate among all the countries. To evaluate the KPI status, we found that children in Africa may have lower school completion rate and children in North America have higher school completion and different countries have different conditions. Thus, we set different KPI goals for different regions. Details of the cube can be found in "SSAS" file.

##  Machine Learning Method
In this part, we aimed to predict whether the school completion rate of each country satisfies certain standard by exploiting decision tree algorithm, based on the collected information of each country including the total violence rate, total child labour rate, rural population and urban population. 

For data processing, the missing values were filled by the mean value of the input data the ratio of our training and testing data split was 75%:25% (Same as SSAS select percentage of train test data). The comparison standard was set to be the mean values of all countries. The best depth of the decision tree was determined by using grid search and cross validation. Details of the ML can be found in "Data Mining" file.
