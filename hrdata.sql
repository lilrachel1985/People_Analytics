DROP TABLE Human_Resource;
SELECT * FROM dbo.['Human Resources$']; 

--Renamed a table to Human_Resource
SELECT * FROM dbo.Human_Resource;

--Data Cleaning 
--Renaming a column name 'id' to 'emp_id'
EXEC sp_RENAME  'Human_Resource.id','emp_id'

--Renaming a column name 'birthdate' to 'birth_date'
EXEC sp_RENAME  'Human_Resource.birthdate','birth_date'

--Renaming a column name 'jobtitle' to 'job_title'
EXEC sp_RENAME  'Human_Resource.jobtitle','job_title'

--Renaming a column name 'termdate' to 'term_date'
EXEC sp_RENAME  'Human_Resource.termdate','term_date'

--Checking Duplicates
SELECT DISTINCT(emp_id)
FROM Human_Resource
GROUP BY emp_id
HAVING COUNT(*)>1;

--Drop all the rows having null values
DELETE FROM Human_Resource 
WHERE emp_id IS NULL;

--Checking the data type of the columns
SELECT COLUMN_NAME,DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'Human_Resource';

--Changing birth date datatype
UPDATE Human_Resource
SET birth_date = CASE WHEN birth_date LIKE '%/%'
                      THEN CONVERT(VARCHAR(10),birth_date, 101)
					  WHEN birth_date LIKE '%-%'
					  THEN CONVERT(VARCHAR(10),birth_date ,110)
					  END;

ALTER TABLE Human_Resource
ALTER COLUMN birth_date DATE;

--Changing term_date datatype
UPDATE Human_Resource
SET term_date = CASE WHEN term_date LIKE '%/%'
                      THEN CONVERT(VARCHAR(10),term_date, 101)
					  WHEN term_date LIKE '%-%'
					  THEN CONVERT(VARCHAR(10),term_date ,110)
					  END;

ALTER TABLE Human_Resource
ALTER COLUMN term_date DATE;

--Checked and Removed where term date greater than today's date
--1465 rows affected because of term_date
DELETE FROM Human_Resource
WHERE birth_date>CURRENT_TIMESTAMP;

DELETE FROM Human_Resource
WHERE term_date>CURRENT_TIMESTAMP;

--Checking gender column
SELECT DISTINCT(gender)
FROM Human_Resource;

--Checking race column
SELECT DISTINCT(race)
FROM Human_Resource;

--Checking for empty values
SELECT *
FROM Human_Resource
WHERE race IS NULL OR gender IS NULL;

--Adding a new column for age
ALTER TABLE Human_Resource
ADD age INT;

--Calculating the age 
UPDATE Human_Resource
SET age =(year(CURRENT_TIMESTAMP) - year(birth_date));

--Checking for inconsistencies
SELECT min(age),max(age),avg(age)
FROM Human_Resource;

--Checking if there is any age is less than 18
SELECT count(*)
FROM Human_Resource
WHERE age < 18;


--ANALYSIS
--GENDER AND RACE DISTRIBUTION
--1. What is the gender breakdown of employees in the company?
SELECT gender, COUNT(gender)AS gender_count
FROM Human_Resource
GROUP BY gender 
ORDER BY gender_count desc;

--2. What is the race/ethnicity breakdown of employees in the company?
SELECT race, COUNT(race) AS race_count
FROM Human_Resource
GROUP BY race
ORDER BY race_count desc; 

--Age distribution
--What is the age distribution of employees in the company?
SELECT count(*)AS num_employees,* FROM

(SELECT 
    CASE 
	WHEN age < 30 THEN 'Youth(20-29)'
	WHEN age < 40 THEN 'Middle-Aged(30-39)'
	WHEN age < 50 THEN 'Senior(40-49)'
	ELSE 'Super Senior(50-59)'
	END AS age_category
	FROM Human_Resource) e
	GROUP BY age_category
	ORDER by age_category desc;

--Work Location
--4.How many employees work at headquarters versus remote location?
SELECT location, count(*) as emp_count
FROM Human_Resource
GROUP BY location
ORDER BY emp_count desc;

--Average Employee Tenure
--5.What is the average length of employment for employees who have been terminated
SELECT AVG(DATEDIFF(year,hire_date, term_date)) AS Average_Length_Employment 
FROM Human_Resource
WHERE term_date IS NOT NULL;


--Gender distribution across departments
--6.How does the gender distribution vary across departments?
SELECT department , gender,count(*) as gender_distribution
FROM Human_Resource
GROUP BY gender,department
ORDER BY department,gender_distribution desc;

--Job Titles Across Company
--7. What is the distribution of job titles across the company?
SELECT job_title, count(*) as job_title_distribution
FROM Human_Resource
GROUP BY job_title
ORDER BY job_title_distribution desc;


-- Turnover Rate in each department
--8. Which department has the highest turnover rate?
SELECT department,
       total_count,
	   term_count,
	    ROUND((total_count/term_count), 1) AS turn_rate
	   FROM(

SELECT department, 
	      
	       COUNT(*) AS total_count,
		   SUM(CASE WHEN term_date IS NOT NULL AND term_date <= CONVERT(date,GETDATE())THEN 1 ELSE 0 END) AS term_count
		   FROM Human_Resource
		   WHERE age >=18
		   GROUP BY department) as d
		   ORDER BY turn_rate DESC
		   ;

--9. What is the turnover rate across job titles
WITH job_title_count AS(
SELECT job_title, count(*) AS total_count,
SUM(CASE WHEN term_date IS NOT NULL THEN 1 ELSE 0 END) AS term_count
FROM Human_Resource
GROUP BY job_title
)
SELECT job_title, total_count/ISNULL(NULLIF(term_count ,0),1) AS turn_rate
FROM job_title_count
ORDER BY turn_rate DESC;

--10. How have turnover rates changed each year

WITH year_cte AS(
SELECT year(hire_date) AS year,
count(*) AS total_count,
SUM(CASE WHEN term_date IS NOT NULL THEN 1 ELSE 0 END) AS term_count
FROM Human_Resource
GROUP BY year(hire_date)
)
SELECT year,
ROUND((total_count/term_count),1) AS turn_rate
FROM year_cte
ORDER BY turn_rate DESC;

--What is the distribution of employees across City and State?
SELECT location,location_state,location_city,COUNT(*) AS num_employees
FROM Human_Resource
WHERE age>=18 AND term_date IS NULL
GROUP BY location,location_state,location_city
ORDER BY num_employees desc;

 

