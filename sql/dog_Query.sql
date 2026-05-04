CREATE DATABASE DogDB;
USE DogDB;

-- 1. Creating the 'data table' to store the unprocessed data
CREATE TABLE DataTable 
(
id INT AUTO_INCREMENT PRIMARY KEY,
Owner_name VARCHAR(100),
Dog_name VARCHAR(55),
Breed VARCHAR(55), 
Age INT,
Converted_age INT,
Weight DECIMAL (5,2),
Log_date VARCHAR(100)
);

-- 2. Import the .txt file with the raw data
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dog_sample_.txt' 
IGNORE INTO TABLE DataTable
FIELDS TERMINATED BY ' | '
LINES TERMINATED BY '\n'
IGNORE 0 ROWS
(Owner_name, Dog_name, Breed, Age, Converted_age, Weight, Log_date);

-- 3. Verify and remove duplicate records
SELECT Owner_name, COUNT(*)
FROM DataTable
GROUP BY  Owner_name
HAVING COUNT(*) > 1;

SET SQL_SAFE_UPDATES = 0;

DELETE t1 FROM DataTable t1
INNER JOIN DataTable t2 
ON t1.Owner_name = t2.Owner_name
	AND t1.Dog_name = t2.Dog_name
	AND t1.Breed = t2.Breed
	AND t1.Age = t2.Age 
WHERE t1.id > t2.id;

-- 4. Spaces, uppercase and lowercase letters
UPDATE DataTable SET
Owner_name = TRIM(Owner_name),
Dog_name = TRIM(Dog_name),
Breed = TRIM(Breed);

UPDATE DataTable SET 
    Owner_name = REPLACE(Owner_name, '﻿', ''), 
    Breed = REPLACE(Breed, '﻿', '');

UPDATE DataTable SET
    Owner_name = CASE 
        WHEN Owner_name LIKE '% %' THEN 
            CONCAT(UPPER(LEFT(Owner_name, 1)), LOWER(SUBSTRING(Owner_name, 2, LOCATE(' ', Owner_name) - 1)), 
                   UPPER(SUBSTRING(Owner_name, LOCATE(' ', Owner_name) + 1, 1)), LOWER(SUBSTRING(Owner_name, LOCATE(' ', Owner_name) + 2)))
        ELSE CONCAT(UPPER(LEFT(Owner_name, 1)), LOWER(SUBSTRING(Owner_name, 2)))
    END,
    Breed = CASE 
        WHEN Breed LIKE '% %' THEN 
            CONCAT(UPPER(LEFT(Breed, 1)), LOWER(SUBSTRING(Breed, 2, LOCATE(' ', Breed) - 1)), 
                   UPPER(SUBSTRING(Breed, LOCATE(' ', Breed) + 1, 1)), LOWER(SUBSTRING(Breed, LOCATE(' ', Breed) + 2)))
        ELSE CONCAT(UPPER(LEFT(Breed, 1)), LOWER(SUBSTRING(Breed, 2)))
    END,
    Dog_name = CONCAT(UPPER(LEFT(Dog_name, 1)), LOWER(SUBSTRING(Dog_name, 2)));

-- 5. Verify and correct errors in dog breeds
SELECT Breed FROM DataTable GROUP BY breed ORDER BY breed ASC;

UPDATE DataTable 
SET Breed = CASE 
    WHEN Breed LIKE 'Gold% Ret%' THEN 'Golden Retriever'
    WHEN Breed LIKE 'German Shep%' OR Breed LIKE 'German Shepa%' THEN 'German Shepherd'
    WHEN Breed LIKE 'Dach%' OR Breed LIKE 'Dash%' THEN 'Dachshund'
    WHEN Breed LIKE 'French Bul%' THEN 'French Bulldog'
    WHEN Breed LIKE 'Siberian Husk%' THEN 'Siberian Husky'
    WHEN Breed IN ('Chihuaua', 'Chiuahua') THEN 'Chihuahua'
    WHEN Breed IN ('Podle', 'Pudle') THEN 'Poodle'
    WHEN Breed IN ('Beaggle', 'Begle') THEN 'Beagle'
    ELSE Breed 
END;

-- 6. Verification of anomalies in relation to: age, breed and weight

-- Puppy with unrealistic weight:
SELECT Breed, Dog_name, Age, Weight, 'Puppy with unrealistic weight' AS Warning
FROM DataTable
WHERE Age = 0 
AND (
    (Breed = 'Chihuahua' AND Weight > 4) OR
    (Breed = 'Poodle' AND Weight > 10) OR
    (Breed = 'Beagle' AND Weight > 10) OR
    (Breed = 'Dachshund' AND Weight > 8) OR
    (Breed = 'French Bulldog' AND Weight > 12) OR
    (Weight > 15)
)
ORDER BY Breed;

UPDATE DataTable 
SET Weight = 
CASE
	WHEN Breed = 'Chihuahua' THEN FLOOR(1 + (RAND() * 2))   
	WHEN Breed = 'Poodle' THEN FLOOR(1 + (RAND() * 4))   
	WHEN Breed = 'Beagle' THEN FLOOR(2 + (RAND() * 5))  
	WHEN Breed = 'Dachshund' THEN FLOOR(1 + (RAND() * 5)) 
	WHEN Breed = 'French Bulldog' THEN FLOOR(2 + (RAND() * 6))   
    ELSE FLOOR(3 + (RAND() * 10)) 
END
WHERE Age = 0 
And (
	(Breed = 'Chihuahua' AND Weight > 4) OR
    (Breed = 'Poodle' AND Weight > 10) OR
    (Breed = 'Beagle' AND Weight > 10) OR
    (Breed = 'Dachshund' AND Weight > 8) OR
    (Breed = 'French Bulldog' AND Weight > 12) OR
    (Weight > 15)
);

-- The rest of the dogs' weights, by size and age
UPDATE DataTable SET Weight =
CASE
    -- SMALL
		WHEN Breed IN ('Chihuahua','Dachshund') AND Age BETWEEN 1 AND 2 THEN FLOOR(1 + RAND()*4)
		WHEN Breed IN ('Chihuahua','Dachshund') AND Age BETWEEN 3 AND 10 THEN FLOOR(2 + RAND()*6)
		WHEN Breed IN ('Chihuahua','Dachshund') AND Age BETWEEN 11 AND 30 THEN FLOOR(2 + RAND()*5)
    -- MEDIUM
		WHEN Breed IN ('Beagle','French Bulldog','Poodle') AND Age BETWEEN 1 AND 2 THEN FLOOR(3 + RAND()*7)
		WHEN Breed IN ('Beagle','French Bulldog','Poodle') AND Age BETWEEN 3 AND 10 THEN FLOOR(6 + RAND()*14)
		WHEN Breed IN ('Beagle','French Bulldog','Poodle') AND Age BETWEEN 11 AND 30 THEN FLOOR(5 + RAND()*13)
    -- LARGE
		WHEN Age BETWEEN 1 AND 2 THEN FLOOR(5 + RAND()*10)
		WHEN Age BETWEEN 3 AND 10 THEN FLOOR(10 + RAND()*20)
		WHEN Age BETWEEN 11 AND 30 THEN FLOOR(8 + RAND()*17)
    ELSE Weight
END
WHERE Age BETWEEN 1 AND 30
AND (
    -- SMALL with incoherent features
    (Breed IN ('Chihuahua','Dachshund') AND (
        (Age BETWEEN 1 AND 2 AND (Weight < 1 OR Weight > 5)) OR
        (Age BETWEEN 3 AND 10 AND (Weight < 2 OR Weight > 8)) OR
        (Age BETWEEN 11 AND 30 AND (Weight < 2 OR Weight > 7))
    ))
    OR
    -- MEDIUM with incoherent features
    (Breed IN ('Beagle','French Bulldog','Poodle') AND (
        (Age BETWEEN 1 AND 2 AND (Weight < 3 OR Weight > 10)) OR
        (Age BETWEEN 3 AND 10 AND (Weight < 6 OR Weight > 20)) OR
        (Age BETWEEN 11 AND 30 AND (Weight < 5 OR Weight > 18))
    ))
    OR
    -- LARGE with incoherent features
    (Breed NOT IN ('Chihuahua','Dachshund','Beagle','French Bulldog','Poodle') AND (
        (Age BETWEEN 1 AND 2 AND (Weight < 5 OR Weight > 15)) OR
        (Age BETWEEN 3 AND 10 AND (Weight < 10 OR Weight > 30)) OR
        (Age BETWEEN 11 AND 30 AND (Weight < 8 OR Weight > 25))
))); 

-- 7. Change Varchar type to Date in Log_date column
ALTER TABLE DataTable ADD Log_date_dt DATETIME;

UPDATE DataTable
SET Log_date_dt = STR_TO_DATE(
    REPLACE(REPLACE(Log_date, ' a. m.', ' AM'), ' p. m.', ' PM'), '%d/%m/%Y %h:%i %p'
);

ALTER TABLE DataTable DROP COLUMN Log_date;
ALTER TABLE DataTable CHANGE Log_date_dt Log_date DATETIME;
