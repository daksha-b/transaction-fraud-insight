import pyodbc
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# Connect to MSSQL
conn = pyodbc.connect(
    "Driver={SQL Server};"
    "Server=DESKTOP-679DH16\SQLEXPRESS;"
    "Database=FinancialTransaction;"
    "Trusted_Connection=yes;"
)

# Query data
print("CUSTOMER DATA")
query1 = "SELECT * FROM customer_data"
transactions1 = pd.read_sql(query1, conn)
print(transactions1.head())

print("\nACCOUNT ACTIVITY")
query2 = "SELECT * FROM account_activity"
transactions2 = pd.read_sql(query2, conn)
print(transactions2.head())

print("\nFRAUD INDICATORS")
query3 = "SELECT * FROM fraud_indicators"
transactions3 = pd.read_sql(query3, conn)
print(transactions3.head())

print("\nSUSPICIOUS ACTIVITY")
query4 = "SELECT * FROM suspicious_activity"
transactions4 = pd.read_sql(query4, conn)
print(transactions4.head())

print("\nMERCHANT DATA")
query5 = "SELECT * FROM merchant_data"
transactions5 = pd.read_sql(query5, conn)
print(transactions5.head())

print("\nTRANSACTION CATEGORY LABELS")
query6 = "SELECT * FROM transaction_category_labels"
transactions6 = pd.read_sql(query6, conn)
print(transactions6.head())

print("\nAMOUNT DATA")
query7 = "SELECT * FROM amount_data"
transactions7 = pd.read_sql(query7, conn)
print(transactions7.head())

print("\nANOMALY SCORES")
query8 = "SELECT * FROM anomaly_scores"
transactions8 = pd.read_sql(query8, conn)
print(transactions8.head())

print("\nTRANSACTION METADATA")
query9 = "SELECT * FROM transaction_metadata"
transactions9 = pd.read_sql(query9, conn)
print(transactions9.head())

print("\nTRANSACTION RECORDS")
query10 = "SELECT * FROM transaction_records"
transactions10 = pd.read_sql(query10, conn)
print(transactions10.head())

#Data Cleaning

# Drop duplicates
transactions10.drop_duplicates(inplace=True)

# Handle missing values
transactions10.fillna({'column_name': 0}, inplace=True)


#EDA - Exploratory Data Analysis

import seaborn as sns
import matplotlib.pyplot as plt

# Plot transaction amounts
sns.boxplot(x='TransactionID', y='Amount', data=transactions10)
plt.show()

sns.boxplot(x='TransactionID', y='FraudIndicator', data=transactions3)
plt.show()




