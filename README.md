# AtliQ_Mart_Retail_Promotion_Analysis_Excel
A project aimed at providing tangible insights to Sales Director, helping them understand which promotions are working and which are not so they can make informed decisions for the next promotional period.

Tools used: Excel, PowerPoint, Word

## I. Description
This project involved analyzing AtliQ Mart's promotional results to find meaningful insights that the Sales Director could use to drive action.

### 1. Problem Statement
AtliQ Mart is a retail giant with over 50 Supermarkets in the southern region of India. All their 50 stores ran a massive promotion during the Diwali 2023 and Sankranti 2024 (festive time in India) on their AtliQ branded products. Now the sales director wants to understand which promotions did well and which did not so that they can make informed decisions for their next promotional period.

### 2. Goals of the Study
The main objectives of this case study are as follows:
1. To develop query capabilities, and optimize SQL queries.
2. To develop report design skills to easily track and analyze data.
3. To develop deeper data analysis capabilities, helping yourself detect trends, patterns and relationships in data.

### 3. Ethical Considerations:
This data is provided by CodeX and used according to the rules provided on the Codebasics Resume Project Challenge page for exploratory analysis. There is no personally identifiable information (PII) in this dataset.

### 4. Table of Contents
- Preparation:
  - Introduce About Company
  - Problem Statement
- Exploratory Data Analyst
  - Stores Performance
  - Promotion Types
  - Products and Categories
- Summary and Recommendations for AtliQ Mart

## II. Data
This data has been provided by the AtliQ Mart and used according to the rules provided on the Codebasics Resume Project Challenge page for exploratory analysis.
- Data is provided in 3 CSV files:
1. [dim_campaigns](Resources/dim_campaigns.csv)
2. [dim_products](Resources/dim_products.csv)
3. [dim_stores](Resources/dim_stores.csv)
4. [fact_events](Resources/fact_events.csv)

Details here: [Meta_data Description](Resources/meta_data.txt)

- Other:
1. [Ad-hoc Requests](Resources/ad-hoc-requests.pdf)
2. [Problem Statement](Resources/problem_statement.pdf)
3. [Recommended Insights](Resources/Recommended Insights.pdf)
4. [SQL Queries](Resources/SQLQuery.sql)
5. [DB SQL SERVER](Resources/retail_events_db_sql_server.sql)

## III. Data Model
![Data Model](https://github.com/user-attachments/assets/0b54fac2-c6df-4ead-a8fc-c9cf36b792b6)

## IV. Results
### 1. Stores Performance
#### Overview:
![image](https://github.com/user-attachments/assets/be83d913-8a42-40d3-9330-4917d1fb8cbf)

#### Number of Store by City:
![image](https://github.com/user-attachments/assets/30b18719-2840-4ebd-a4d8-8928993cc140)

#### Total Revenue Before and After Promotion by City:
![image](https://github.com/user-attachments/assets/29a66330-584e-4922-b39f-e04f9d8a7a1c)

#### Total Sales Volume Before and After Promotion by City:
![image](https://github.com/user-attachments/assets/c95830d3-1520-4750-a59a-4631469be24c)

#### Top 10 Incremental Revenue by Store:
![image](https://github.com/user-attachments/assets/833744b0-7a60-4351-85a6-865d2d9fc162)

#### Bottom 10 Incremental Revenue by Store:
![image](https://github.com/user-attachments/assets/7b9cf0b3-e11d-4a38-968d-8875c68a59a0)

#### Top 10 Incremental Sold Units by Store:
![image](https://github.com/user-attachments/assets/f62fbc74-35f2-443c-8545-db6afbaf4c32)

#### Bottom 10 Incremental Sold Units by Store:
![image](https://github.com/user-attachments/assets/ebb31291-ff51-4882-8f85-8c311fb603a6)


### 2. Promotion Types
#### Overview:
![image](https://github.com/user-attachments/assets/379439b8-0da6-47b4-85a5-a2208af72f27)

#### Incremental Sold Units (and Percentage) by Promotion Types:
![image](https://github.com/user-attachments/assets/429aaf75-6bdc-454d-98fd-5b93fccb5aa7)

#### Incremental Revenue (and Percentage) by Promotion Types:
 ![image](https://github.com/user-attachments/assets/3853f7bd-37d2-4de3-9bde-5eb881f142a5)

#### Incremental Sold Units (and Percentage) by Promotion Types and Categories:
![image](https://github.com/user-attachments/assets/5fcccae1-0408-456b-91ff-46e89ddbf80c)

#### Incremental Revenue (and Percentage) by Promotion Types and Categories:
![image](https://github.com/user-attachments/assets/e1d0e4b6-8f0a-45cd-bacb-ca87d752ee67)


### 3. Products and Categories
#### Overview:
![image](https://github.com/user-attachments/assets/9172c66b-d4e6-4c5b-9739-cb785464f003)

#### Incremental Sold Units by Categories:
![image](https://github.com/user-attachments/assets/f8ff7ce9-840c-4c36-8b87-fef4f006c78d)

#### Incremental Revenue by Categories:
![image](https://github.com/user-attachments/assets/759ead54-6560-4c4f-877e-0f25446269be)

#### Incremental Sold Units (and Percentage) by Categories and Promotion Types:
![image](https://github.com/user-attachments/assets/bab26dd5-3388-4321-9529-4df55bcb4471)

#### Incremental Revenue (and Percentage) by Categories and Promotion Types:
![image](https://github.com/user-attachments/assets/ad8f099f-8957-4194-bab3-e20b176547ed)

#### Top Products by IR:
##### Top 5 Incremental Revenue by Products:
![image](https://github.com/user-attachments/assets/e5f06322-6225-4d72-92e1-1a4449b2876f)

##### Top 5 Incremental Revenue Percentage by Products:
![image](https://github.com/user-attachments/assets/39441b4d-f9d9-4bb5-9e28-1b2f7a762e3f)

##### Bottom 5 Incremental Revenue by Products:
![image](https://github.com/user-attachments/assets/0f0c2aa7-9870-470e-9faa-cebb144108bb)

##### Bottom 5 Incremental Revenue Percentage by Products:
![image](https://github.com/user-attachments/assets/838bc1db-563e-49e0-b901-2ed2209fb4cf)

#### Top Products by ISU:
##### Top 5 Incremental Sold Units by Products:
![image](https://github.com/user-attachments/assets/ad7c0b1b-68e1-4cf4-847b-05a3a08db2ae)

##### Top 5 Incremental Sold Units Percentage by Products:
![image](https://github.com/user-attachments/assets/efc5e503-99c9-4e0d-b485-c18a3aec91de)

##### Bottom 5 Incremental Sold Units by Products:
![image](https://github.com/user-attachments/assets/f659c0f4-1240-4e1c-9005-e7280b76512e)

##### Bottom 5 Incremental Sold Units Percentage by Products:
![image](https://github.com/user-attachments/assets/0623d36d-1cef-4dee-bba2-857d9ddefc2b)


### 4. Summary and Recommendations
#### 4.1. Summary
![image](https://github.com/user-attachments/assets/b475fbd5-2566-4c85-bf9f-7c9ff6c4c3ef)


#### 4.2. Recommendations for AtliQ Mart
![image](https://github.com/user-attachments/assets/872d8f7f-e4fd-45c1-9415-5a86f0d2672a)


## VI. Contributing
Contributions are welcome! Please send me an email for any suggestions or improvements.

Email:[nhudaitran1510@gmail.com](mailto:nhudaitran1510@gmail.com)

## VII. Author
Created by [Nhu Dai Tran](https://github.com/WalterEdwardd)

<img src="https://github.com/user-attachments/assets/01b769fa-5c75-44db-819f-3fc8781c7e98" alt="Description" width="300" height="400">
