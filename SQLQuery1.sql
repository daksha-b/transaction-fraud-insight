--List all transaction details (transaction ID, date, amount) along with the customer name and ID.
use FinancialTransaction;
SELECT T.TransactionID, A.LastLogin, T.Amount, C.Name, T.CustomerID
FROM     transaction_records AS T INNER JOIN
                  customer_data AS C ON T.CustomerID = C.CustomerID INNER JOIN
                  account_activity AS A ON C.CustomerID = A.CustomerID;

--Find the total number of transactions made by each customer.
SELECT CustomerID, COUNT(*) AS NoOfTransactions
FROM     transaction_records
GROUP BY CustomerID;

--Get the total transaction amount for each customer
SELECT CustomerID, SUM(Amount) AS TotalAmount
FROM     transaction_records
GROUP BY CustomerID;

--Find all transactions above a specific amount threshold 
SELECT TransactionID, Amount
FROM     transaction_records
WHERE  (Amount > 10 and Amount <30);

--List the top 5 transactions with the highest amounts.
SELECT TOP (5) TransactionID, Amount
FROM     transaction_records
ORDER BY Amount DESC;

--List details of customers whose transactions were flagged as suspicious.
SELECT C.CustomerID, C.Name, C.Age, C.Address, T.TransactionID, S.SuspiciousFlag
FROM     suspicious_activity AS S INNER JOIN
                  customer_data AS C ON C.CustomerID = S.CustomerID INNER JOIN
                  transaction_records AS T ON T.CustomerID = S.CustomerID
WHERE  (S.SuspiciousFlag = 1);

--cleaning data as it was imported as varchar
SELECT DISTINCT AnomalyScore
FROM anomaly_scores;

UPDATE anomaly_scores
SET AnomalyScore = NULL
WHERE ISNUMERIC(AnomalyScore) = 0;

UPDATE anomaly_scores
SET AnomalyScore = LTRIM(RTRIM(AnomalyScore));

ALTER TABLE anomaly_scores ALTER COLUMN AnomalyScore NUMERIC(25, 24);

SELECT *
FROM anomaly_scores
WHERE AnomalyScore IS NOT NULL;


--Find transactions with anomaly scores above a threshold (e.g., 0.9)

SELECT A.transactionid, A.anomalyscore, T.amount
FROM anomaly_scores A
JOIN transaction_records T ON A.transactionid = T.transactionid
WHERE A.anomalyscore > 0.9;


--Changing data type of timestamp from varchar to datetiem2
ALTER TABLE transaction_metadata ALTER COLUMN Timestamp DATETIME2;
select * from transaction_metadata;
sp_help transaction_metadata;

--Summarize the total transaction amount per month.
SELECT MONTH(M.Timestamp) AS month, SUM(T.Amount) AS sum
FROM     transaction_records AS T INNER JOIN
                  transaction_metadata AS M ON T.TransactionID = M.TransactionID
GROUP BY MONTH(M.Timestamp);

alter table transaction_metadata alter column transactionID varchar(255);
alter table transaction_metadata add constraint fk_tr_id_meta FOREIGN KEY(transactionID) references transaction_records(transactionID);

--List merchants with the most transactions flagged as suspicious.
SELECT M.MerchantID, M.MerchantName, COUNT(T.TransactionID) AS NoOfSusTransactions
FROM     merchant_data AS M INNER JOIN
                  transaction_metadata AS T ON T.MerchantID = M.MerchantID INNER JOIN
                  transaction_records AS Tr ON T.TransactionID = Tr.transactionID INNER JOIN
                  suspicious_activity AS S ON Tr.customerID = S.CustomerID
WHERE  (S.suspiciousflag = 1)
GROUP BY M.MerchantID, M.MerchantName
ORDER BY NoOfSusTransactions DESC;

--Calculate a "fraud score" for each customer based on the number of suspicious transactions and anomaly scores.
SELECT cd.customerid, cd.name,
       COUNT(Tr.TransactionId) AS suspicious_transactions,
       AVG(ad.anomalyscore) AS average_anomaly_score,
       (COUNT(Tr.TransactionId) * AVG(ad.anomalyscore)) AS fraudScore
FROM customer_data cd
JOIN transaction_records tr ON cd.customerid = tr.customerid
LEFT JOIN suspicious_activity sa ON tr.transactionid = Tr.TransactionId
LEFT JOIN anomaly_scores ad ON tr.transactionid = ad.transactionid
GROUP BY cd.customerid, cd.name
ORDER BY fraudScore DESC;

--Rank merchants by their risk score, defined as the ratio of suspicious(fraud) transactions to total transactions.
SELECT 
    M.MerchantID, 
    COUNT(CASE WHEN F.FraudIndicator = 1 THEN F.TransactionID END) AS FraudTransactions, 
    COUNT(T.TransactionID) AS TotalTransactions, 
    CASE 
        WHEN COUNT(T.TransactionID) = 0 THEN 0 
        ELSE CAST(COUNT(CASE WHEN F.FraudIndicator = 1 THEN F.TransactionID END) AS FLOAT) / COUNT(T.TransactionID) 
    END AS RiskScore
FROM 
    merchant_data M
JOIN 
    transaction_metadata T ON T.MerchantID = M.MerchantID
LEFT JOIN 
    fraud_indicators F ON F.TransactionID = T.TransactionID
GROUP BY 
    M.MerchantID
ORDER BY 
    RiskScore DESC;

--Find customers who have not made any transactions in the past year.
SELECT DISTINCT 
    cd.customerid, 
    cd.name,
	tm.timestamp
FROM 
    customer_data cd
LEFT JOIN 
    transaction_records tr ON cd.customerid = tr.customerid
JOIN 
    transaction_metadata tm ON tm.transactionID = tr.transactionID
WHERE 
    tm.timestamp IS NULL 
    OR tm.timestamp < DATEADD(YEAR, -1, GETDATE());

--Find the transaction categories associated with the highest number of fraud transactions.
SELECT C.Category, COUNT(C.TransactionID) AS NoOfFraudTransactions
FROM     transaction_category_labels AS C INNER JOIN
                  fraud_indicators AS F ON F.TransactionID = C.TransactionID
WHERE  (F.FraudIndicator = 1)
GROUP BY C.Category
ORDER BY NoOfFraudTransactions DESC;

--Compute the total transaction amount and average transaction value for each customer.
SELECT cd.customerid, cd.name,
       SUM(tr.amount) AS total_spent,
       AVG(tr.amount) AS avg_transaction_value
FROM customer_data cd
JOIN transaction_records tr ON cd.customerid = tr.customerid
GROUP BY cd.customerid, cd.name
ORDER BY total_spent DESC;

--Detect merchants with high-value transactions significantly exceeding their average transaction amount.
WITH MerchantAvg AS (SELECT M.MerchantID, M.MerchantName, AVG(A.TransactionAmount) AS AvgTransactionAmount
                                               FROM      merchant_data AS M INNER JOIN
                                                                 transaction_metadata AS T ON M.MerchantID = T.MerchantID INNER JOIN
                                                                 amount_data AS A ON A.TransactionID = T.TransactionID
                                               GROUP BY M.MerchantID, M.MerchantName)
    SELECT M.MerchantID, M.MerchantName, A.TransactionAmount, MA.AvgTransactionAmount
    FROM     merchant_data AS M INNER JOIN
                      transaction_metadata AS T ON M.MerchantID = T.MerchantID INNER JOIN
                      amount_data AS A ON A.TransactionID = T.TransactionID INNER JOIN
                      MerchantAvg AS MA ON M.MerchantID = MA.MerchantID AND A.TransactionAmount > MA.AvgTransactionAmount * 2
    ORDER BY A.TransactionAmount DESC