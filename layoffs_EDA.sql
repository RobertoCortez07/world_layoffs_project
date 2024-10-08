-- Exploratory Data Analysis

SELECT *
FROM layoff_staging;

-- Selecting the highest number of laid off employees at once
SELECT MAX(total_laid_off)
FROM layoff_staging;

-- Selecting the companies with the highest percentage of laid off employees (1 = 100%))
SELECT *
FROM layoff_staging
where percentage_laid_off = 1;

-- Selecting the companies with the highest number of laid off employees in this time period
SELECT company, SUM(total_laid_off)
FROM layoff_staging
WHERE total_laid_off IS NOT NULL
GROUP BY company
ORDER BY 2 DESC;

-- Selecting the industries with the highest number of laid off employees
SELECT industry, SUM(total_laid_off) AS total_laid_off
FROM layoff_staging
WHERE total_laid_off IS NOT NULL
GROUP BY industry
ORDER BY 2 DESC;

-- Selecting the cities/regions with the highest number of laid off employees
SELECT location, SUM(total_laid_off) AS total_laid_off
FROM layoff_staging
WHERE total_laid_off IS NOT NULL
GROUP BY location
ORDER BY 2 DESC;

-- Selecting the countries with the highest number of laid off employees
SELECT country, SUM(total_laid_off) AS total_laid_off
FROM layoff_staging
WHERE total_laid_off IS NOT NULL
GROUP BY country
ORDER BY 2 DESC;

-- Selecting the years with the highest number of laid off employees
SELECT EXTRACT(YEAR FROM date) AS year, SUM(total_laid_off) AS total_laid_off
FROM layoff_staging
WHERE date IS NOT NULL
  AND total_laid_off IS NOT NULL
GROUP BY year
ORDER BY 1 DESC;



-- Creating a rolling total of laid off employees by month
WITH rolling_total AS (SELECT date_trunc('month', date)::date AS year_month, SUM(total_laid_off) AS total_laid_off
                       FROM layoff_staging
                       WHERE date IS NOT NULL
                         AND total_laid_off IS NOT NULL
                       GROUP BY year_month
                       ORDER BY 1)
SELECT year_month, total_laid_off, SUM(total_laid_off) OVER (ORDER BY year_month) AS rolling_total
FROM rolling_total;


-- Ranking the companies with the highest number of laid off employees by year
WITH company_year (company, year, total_laid_off)
         AS (SELECT company, EXTRACT(YEAR FROM date) AS year, SUM(total_laid_off)
             FROM layoff_staging
             WHERE total_laid_off IS NOT NULL
             GROUP BY company, year),
     company_year_rank AS (SELECT *, DENSE_RANK() OVER (PARTITION BY year ORDER BY total_laid_off DESC) AS rank
                           FROM company_year)
SELECT *
FROM company_year_rank
WHERE rank <= 5
  AND year is not null;

-- Calculating an estimate of the total number of employees for each company
SELECT company,
       total_laid_off,
       percentage_laid_off,
       ROUND((total_laid_off / percentage_laid_off)) AS total_employees,
       date
FROM layoff_staging
WHERE total_laid_off IS NOT NULL
  AND percentage_laid_off IS NOT NULL
  AND percentage_laid_off != 0
ORDER BY company;

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


