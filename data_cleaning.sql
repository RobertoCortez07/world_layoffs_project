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

-- 1. Remove any duplicates
-- 2. Standardize the data
-- 3. Null or blank values
-- 4. Remove any rows that are not needed

-- Creating a duplicate table to modify the data
CREATE TABLE layoff_staging AS
SELECT *
FROM layoffs;

-- 1. Removing duplicates
-- Creating a query that checks for duplicates
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

-- Checking if there are any duplicates left
WITH duplicate_CTE AS (SELECT *,
                              row_number()
                              OVER (PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions) AS row_num
                       FROM layoff_staging)
SELECT *
FROM duplicate_CTE
WHERE row_num > 1;

-- 2. Standardizing the data

-- Removing any leading or trailing spaces
UPDATE layoff_staging
SET company = TRIM(company);

-- Converting all the crypto related industries to 'Crypto'
UPDATE layoff_staging
SET industry = 'Crypto'
WHERE industry LIKE '%Crypto%';

--Removing a period from a country name
UPDATE layoff_staging
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Converting the date column to a date type
UPDATE layoff_staging
SET date = to_date(date, 'MM/DD/YY');

ALTER TABLE layoff_staging
ALTER COLUMN date TYPE DATE USING date::date;

-- Converting the total_laid_off, percentage_laid_off, and funds_raised_millions columns to INT and DECIMAL
ALTER TABLE layoff_staging
ALTER COLUMN total_laid_off TYPE INT USING total_laid_off::INT;

ALTER TABLE layoff_staging
ALTER COLUMN percentage_laid_off TYPE DECIMAL USING percentage_laid_off::DECIMAL;

ALTER TABLE layoff_staging
ALTER COLUMN funds_raised_millions TYPE DECIMAL USING funds_raised_millions::DECIMAL;

-- Finding and replacing the string 'NULL' with an actual NULL value
SELECT * FROM layoff_staging
WHERE company = 'NULL'
OR location = 'NULL'
OR industry = 'NULL'
OR total_laid_off = 'NULL'
OR percentage_laid_off = 'NULL'
OR date = 'NULL'
OR stage = 'NULL'
OR country = 'NULL'
OR funds_raised_millions = 'NULL';

UPDATE layoff_staging
SET industry = NULL
WHERE industry = 'NULL';

UPDATE layoff_staging
SET total_laid_off = NULL
WHERE total_laid_off = 'NULL';

UPDATE layoff_staging
SET percentage_laid_off = NULL
WHERE percentage_laid_off = 'NULL';

UPDATE layoff_staging
SET date = NULL
WHERE date = 'NULL';

UPDATE layoff_staging
SET stage = NULL
WHERE stage = 'NULL';

UPDATE layoff_staging
SET funds_raised_millions = NULL
WHERE funds_raised_millions = 'NULL';

-- Removing NULLs from industry column

UPDATE layoff_staging t1
SET industry = t2.industry
FROM layoff_staging t2
WHERE t1.company = t2.company
  AND t1.location = t2.location
  AND t1.industry IS NULL
  AND t2.industry IS NOT NULL;

-- Deleting rows with NULL values in both total_laid_off and percentage_laid_off
DELETE
FROM layoff_staging
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

