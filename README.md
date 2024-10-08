# World Layoffs Data Cleaning and Exploratory Data Analysis Using SQL

## Introduction
In this project, I do data cleaning and EDA on a layoffs dataset which documents layoffs from various companies from around the world between March, 2020 to March, 2023. 
The data includes the industry of the company, amount of layoffs and percentage of total workforce laid off, city/region and country, date and the amount of funding raised. 

# Tools I Used

For both the data cleaning and EDA portions of this project, I used the following tools:

- SQL: The backbone of my analysis, allowing me to query the database and unearth critical insights.
- PostgreSQL: My main database of choice
- PGAdmin4: For initial import of data
- DataGrip: My main IDE for database management and executing SQL queries.
- Git & GitHub: Essential for version control and sharing my SQL scripts and analysis.

# Part 1. Data Cleaning
- This is a summary of what code I wrote during the data cleaning process. A detailed view of the code can be found [here](data_cleaning.sql)

I begin the project by creating a database and importing the dataset into PGAdmin4 
```sql
CREATE DATABASE world_layoffs;

-- Note: I used the import data feature from pgAdmin and this is the generated SQL
create table layoffs
(
    company               text,
    location              text,
    industry              text,
    total_laid_off        text,
    percentage_laid_off   text,
    date                  text,
    stage                 text,
    country               text,
    funds_raised_millions text
);

\\copy public.layoffs (company, location, industry, total_laid_off, percentage_laid_off, date, stage, country,
                       funds_raised_millions) FROM '...world_layoffs_project/layoffs.csv' DELIMITER ',' CSV HEADER ENCODING 'UTF8' QUOTE '\"' ESCAPE '';

```

Creating a duplicate table in order to preserve the original data
```sql
CREATE TABLE layoff_staging AS
SELECT *
FROM layoffs;
```

Then I followed these 4 steps 
1. Remove any duplicates
```sql
WITH duplicate_CTE AS (SELECT *,
                              row_number()
                              OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
                       FROM layoff_staging)
DELETE
FROM layoff_staging
    USING duplicate_CTE
WHERE company = duplicate_CTE.company
  AND location = duplicate_CTE.location
  AND industry = duplicate_CTE.industry
  AND total_laid_off = duplicate_CTE.total_laid_off
  AND percentage_laid_off = duplicate_CTE.percentage_laid_off
  AND date = duplicate_CTE.date
  AND stage = duplicate_CTE.stage
  AND country = duplicate_CTE.country
  AND funds_raised_millions = duplicate_CTE.funds_raised_millions
  AND duplicate_CTE.row_num > 1;

-- Removing duplicates using a CTE
SELECT *,
       row_number()
       OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
FROM layoff_staging;

```
2. Standardize the data which includes changing some spellings in the data and converting text data types into the appropriate data types
```sql
-- Removing any leading or trailing spaces
UPDATE layoff_staging
SET company = TRIM(company);

-- Converting all the crypto related industries to 'Crypto'
UPDATE layoff_staging
SET industry = 'Crypto'
WHERE industry LIKE '%Crypto%';

-- Converting the date column to a date type
UPDATE layoff_staging
SET date = to_date(date, 'MM/DD/YY');

ALTER TABLE layoff_staging
ALTER COLUMN date TYPE DATE USING date::date;
```

3. Change any text "Null" or blank values into NULL 
```SQL
UPDATE layoff_staging
SET total_laid_off = NULL
WHERE total_laid_off = 'NULL';

UPDATE layoff_staging
SET percentage_laid_off = NULL
WHERE percentage_laid_off = 'NULL';
```

4. Remove any rows that are not needed
```sql
DELETE
FROM layoff_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
```

# Part 2. Exploratory Data Analysis
- After cleaning the data, I answer various questions about the dataset including:
1. What were the companies with the highest amount of layoffs in this time period?
2. Which years had the highest amount of layoffs?
3. How many layoffs were there per month? 
4. Which cities/regions had the highest amount of layoffs.

- A detailed view of my EDA sql code can be found [here](layoffs_EDA.sql)

```sql
SELECT company, SUM(total_laid_off)
FROM layoff_staging
WHERE total_laid_off IS NOT NULL
GROUP BY company
ORDER BY 2 DESC;

-- Selecting the years with the highest number of laid off employees
SELECT EXTRACT(YEAR FROM date) AS year, SUM(total_laid_off) AS total_laid_off
FROM layoff_staging
WHERE date IS NOT NULL
  AND total_laid_off IS NOT NULL
GROUP BY year
ORDER BY 1 DESC;

-- Creating a rolling total of laid off employees by month in the US
WITH rolling_total AS (SELECT date_trunc('month', date)::date AS year_month, SUM(total_laid_off) AS total_laid_off
                       FROM layoff_staging
                       WHERE date IS NOT NULL
                         AND total_laid_off IS NOT NULL
                         AND country = 'United States'
                       GROUP BY year_month
                       ORDER BY 1)
SELECT year_month, total_laid_off, SUM(total_laid_off) OVER (ORDER BY year_month) AS rolling_total
FROM rolling_total;

-- Selecting the cities/regions with the highest number of laid off employees
SELECT location, SUM(total_laid_off) AS total_laid_off
FROM layoff_staging
WHERE total_laid_off IS NOT NULL
GROUP BY location
ORDER BY 2 DESC;
```