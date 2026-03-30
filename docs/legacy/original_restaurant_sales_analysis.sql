use project4;


select * from balaji_fast_food_sales;



CREATE TABLE Staff (
    Staff_ID INTEGER AUTO_INCREMENT PRIMARY KEY,
    Gender CHAR(30) NOT NULL
);

CREATE TABLE Orders (
    Order_ID INTEGER PRIMARY KEY,
    Staff_ID INTEGER NOT NULL,
    Transaction_Amount INTEGER NOT NULL,
    FOREIGN KEY (Staff_ID) REFERENCES Staff(Staff_ID)
);

CREATE TABLE Order_Item (
    Order_ID INTEGER NOT NULL,
    Item_ID INTEGER NOT NULL,
    FOREIGN KEY (Order_ID) REFERENCES Orders(Order_ID),
    FOREIGN KEY (Item_ID) REFERENCES Items(Item_ID)
);

CREATE TABLE Items (
    Item_ID INTEGER AUTO_INCREMENT PRIMARY KEY,
    Item_Name CHAR(30) NOT NULL,
    Item_Type CHAR(30) NOT NULL,
    Item_Price INTEGER NOT NULL
);

CREATE TABLE Payment (
    Payment_ID INTEGER AUTO_INCREMENT PRIMARY KEY,
    Transaction_Type INTEGER NOT NULL,
    Date DATE NOT NULL,
    Time_of_Sale CHAR(30) NOT NULL
);


show tables;


INSERT INTO Staff (Gender) SELECT DISTINCT received_by
FROM balaji_fast_food_sales;

INSERT INTO Items (Item_Name, Item_Type, Item_Price)
SELECT DISTINCT item_name, item_type, item_price
FROM balaji_fast_food_sales;

INSERT INTO Orders (Order_ID, Staff_ID, Transaction_Amount)
SELECT b.order_id, s.Staff_ID, b.transaction_amount
FROM balaji_fast_food_sales b
JOIN Staff s ON b.received_by = s.Gender;

INSERT INTO Order_Item (Order_ID, Item_ID)
SELECT b.order_id, i.Item_ID
FROM balaji_fast_food_sales b
JOIN Items i ON b.item_name = i.Item_Name AND b.item_type = i.Item_Type;

ALTER TABLE Payment
MODIFY Transaction_Type VARCHAR(20);

INSERT INTO Payment (Transaction_Type, Date, Time_of_Sale)
SELECT DISTINCT 
    transaction_type,
    CASE 
        WHEN INSTR(date, '-') > 0 THEN STR_TO_DATE(date, '%d-%m-%Y')
        WHEN INSTR(date, '/') > 0 THEN STR_TO_DATE(date, '%m/%d/%Y')
        ELSE NULL
    END AS date,
    time_of_sale
FROM balaji_fast_food_sales;

select*from Payment;


SELECT * FROM Staff ORDER BY Staff_ID;
SELECT * FROM Items ORDER BY Item_ID;
SELECT * FROM Orders ORDER BY Order_ID;
SELECT * FROM Order_Item ORDER BY Order_ID, Item_ID;

SELECT * FROM Payment ORDER BY Payment_ID;
SELECT * FROM Payment ORDER BY Payment_ID;

SELECT O.Order_ID, O.Transaction_Amount, I.Item_Name, I.Item_Price
FROM Orders O
INNER JOIN Order_Item OI ON O.Order_ID = OI.Order_ID
INNER JOIN Items I ON OI.Item_ID = I.Item_ID;






SELECT O.Order_ID, O.Transaction_Amount, I.Item_Name, I.Item_Price
FROM Orders O
INNER JOIN Order_Item OI ON O.Order_ID = OI.Order_ID
INNER JOIN Items I ON OI.Item_ID = I.Item_ID;




SELECT S.Staff_ID, S.Gender, O.Order_ID
FROM Staff S
LEFT OUTER JOIN Orders O ON S.Staff_ID = O.Staff_ID
ORDER BY S.Staff_ID;


SELECT S.Staff_ID, S.Gender, O.Order_ID
FROM Staff S
LEFT OUTER JOIN Orders O ON S.Staff_ID = O.Staff_ID
ORDER BY S.Staff_ID;




SELECT * FROM Items WHERE Item_Price = (SELECT MAX(Item_Price) FROM Items);


SELECT * FROM Orders
WHERE Staff_ID IN (SELECT Staff_ID FROM Staff WHERE Gender = 'Mr.')
ORDER BY Order_ID;


SELECT Staff_ID, COUNT(Order_ID) AS Number_Of_Orders, SUM(Transaction_Amount) AS Total_Sales
FROM Orders
GROUP BY Staff_ID;









SELECT Staff_ID, COUNT(Order_ID) AS Number_Of_Orders, SUM(Transaction_Amount) AS Total_Sales
FROM Orders
GROUP BY Staff_ID;

SELECT * FROM Staff
WHERE Staff_ID NOT IN (SELECT Staff_ID FROM Orders)
ORDER BY Staff_ID;




SELECT Order_ID, Transaction_Amount,
       CASE 
           WHEN Transaction_Amount > 1000 THEN 'High'
           WHEN Transaction_Amount BETWEEN 500 AND 1000 THEN 'Medium'
           ELSE 'Low'
       END AS Spending_Category
FROM Orders
ORDER BY Order_ID;


SELECT * FROM Staff S
WHERE NOT EXISTS (
    SELECT * FROM Orders O WHERE O.Staff_ID = S.Staff_ID
)
ORDER BY Staff_ID;



SELECT * FROM Staff S
WHERE NOT EXISTS (
    SELECT * FROM Orders O WHERE O.Staff_ID = S.Staff_ID
)
ORDER BY Staff_ID;



SELECT * FROM Orders
WHERE Order_ID NOT IN (
    SELECT Order_ID FROM Payment WHERE Transaction_Type IS NOT NULL
)
ORDER BY Order_ID;










SELECT I.Item_ID, I.Item_Name, P.Transaction_Type
FROM Items I
LEFT JOIN Order_Item OI ON I.Item_ID = OI.Item_ID
LEFT JOIN Orders O ON OI.Order_ID = O.Order_ID
LEFT JOIN Payment P ON O.Order_ID = P.Payment_ID
WHERE NOT EXISTS (
    SELECT 1
    FROM Payment P1
    WHERE P1.Payment_ID = O.Order_ID AND P1.Transaction_Type IS not NULL
)
ORDER BY I.Item_ID;


SELECT DISTINCT I.Item_ID, I.Item_Name
FROM Items I
WHERE EXISTS (
    SELECT 1
    FROM Order_Item OI
    JOIN Orders O ON OI.Order_ID = O.Order_ID
    JOIN Payment P ON O.Order_ID = P.Payment_ID
    WHERE OI.Item_ID = I.Item_ID AND P.Transaction_Type IS NOT NULL
)
ORDER BY I.Item_ID;


SELECT DISTINCT I.Item_ID, I.Item_Name
FROM Items I
WHERE EXISTS (
    SELECT 1
    FROM Order_Item OI
    JOIN Orders O ON OI.Order_ID = O.Order_ID
    JOIN Payment P ON O.Order_ID = P.Payment_ID
    WHERE OI.Item_ID = I.Item_ID AND P.Transaction_Type IS NOT NULL
)
ORDER BY I.Item_ID;




SELECT DISTINCT S.Staff_ID, S.Gender
FROM Staff S
WHERE EXISTS (
    SELECT 1
    FROM Orders O
    WHERE O.Staff_ID = S.Staff_ID AND O.Transaction_Amount IS NOT NULL
)
ORDER BY S.Staff_ID;






SELECT I.Item_ID, I.Item_Name
FROM Items I
WHERE I.Item_ID NOT IN (
    SELECT DISTINCT OI.Item_ID
    FROM Order_Item OI
)
ORDER BY I.Item_ID;





SELECT S.Staff_ID, S.Gender
FROM Staff S
WHERE S.Staff_ID NOT IN (
    SELECT DISTINCT O.Staff_ID
    FROM Orders O
)
ORDER BY S.Staff_ID;


















SELECT DISTINCT P.Transaction_Type
FROM Payment P
WHERE P.Transaction_Type NOT IN (
    SELECT DISTINCT P1.Transaction_Type
    FROM Payment P1
    JOIN Orders O ON P1.Payment_ID = O.Order_ID  -- Assuming Payment_ID links to Order_ID
    WHERE P1.Transaction_Type IS NOT NULL AND O.Transaction_Amount > 0
)
ORDER BY P.Transaction_Type;







