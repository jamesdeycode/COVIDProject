--Select the data to be used
SELECT
	location
	, date
	, total_cases
	, new_cases
	, total_deaths
	, population
FROM
	[CovidProject].[dbo].[CovidDeaths]
ORDER BY
	1,2

--Calculate Total Cases vs Total Deaths Per Country
SELECT
	location Country
	, MAX(CAST(total_deaths AS FLOAT)) TotalDeaths
	, MAX(CAST(total_cases AS float)) TotalCases
	, MAX(CAST(total_deaths AS FLOAT))/MAX(CAST(total_cases AS float))*100 MortalityRate
FROM
	[CovidProject].[dbo].[CovidDeaths]
WHERE
	total_cases IS NOT NULL
	AND total_deaths IS NOT NULL
	AND iso_code NOT LIKE 'OWID%'
GROUP BY
	location
ORDER BY
	MortalityRate DESC

--Calculate Total Cases vs Population Per Country
SELECT
	location Country
	, population Population
	, MAX(CAST(total_cases AS float)) TotalCases
	, MAX(CAST(total_cases AS float))/CAST(population AS float)*100 ContractionRate
FROM
	[CovidProject].[dbo].[CovidDeaths]
WHERE
	total_cases IS NOT NULL
	AND total_deaths IS NOT NULL
	AND iso_code NOT LIKE 'OWID%'
GROUP BY
	location, population
ORDER BY
	4 DESC

--Calculate Death Rate Per Population by Country
SELECT
	location Country
	, MAX(CAST(total_deaths AS float)) TotalDeaths
	, population Population
	, MAX(CAST(total_deaths AS float))/CAST(population AS float)*100 DeathRate
FROM
	[CovidProject].[dbo].[CovidDeaths]
WHERE
	total_cases IS NOT NULL
	AND total_deaths IS NOT NULL
	AND iso_code NOT LIKE 'OWID%'
GROUP BY
	location, population
ORDER BY
	4 DESC

--Calculate Death Rate Per Population by Continent
SELECT
	location Continent
	, MAX(CAST(total_deaths AS float)) DeathCount
	, population 
	, MAX(CAST(total_deaths AS float))/CAST(population AS float)*100 DeathRate
FROM
	[CovidProject].[dbo].[CovidDeaths]
WHERE
	continent is null
GROUP BY
	location
	, population
ORDER BY
	2 DESC

--Total Number of Cases Globally Daily in 2020
SELECT
	date Date
	, SUM(CAST (new_cases AS float)) NumberOfNewCases
FROM
	[CovidProject].[dbo].[CovidDeaths]
WHERE
	date like '2020%'
Group by
	date
Order by
	2 DESC

--Mortality Rates Globally Per Day
--Method 1: Use CASE statement to avoid a zero denominator
SELECT
	date Date
	, SUM(CAST (new_deaths AS float)) NumberOfNewDeaths
	, SUM(CAST (new_cases AS float)) NumberofNewCases
	, CASE
		WHEN SUM(CAST (new_cases AS float)) = 0
		THEN 0
	ELSE
		SUM(CAST (new_deaths AS float))/SUM(CAST (new_cases AS float))
	END AS MortalityRate
FROM
	[CovidProject].[dbo].[CovidDeaths]
Group by
	date
Order by
	4 DESC

--Method 2: Use NULLIF and ISNULL functions to avoid a zero denominator
SELECT
	date Date
	, ISNULL(SUM(CAST (new_deaths AS float)),0) NumberOfNewDeaths
	, ISNULL(SUM(CAST (new_cases AS float)),0) NumberofNewCases
	, ISNULL(SUM(CAST (new_deaths AS float))/(NULLIF(SUM(CAST (new_cases AS float)),0)),0) MortalityRate
FROM
	[CovidProject].[dbo].[CovidDeaths]
Group by
	date
Order by
	4 DESC

--Calculate Total Number of People Vaccinated and Percentage of Population Vaccinated Based on New Daily Vaccinations
--Method 1: Using CTE
;WITH
	DailyVaccNumbers
	(
	Country
	, Date
	, Population
	, NewVaccinations
	, CurrentlyVaccinated
	)
AS
	(
	SELECT
		vacc.location
		, vacc.date
		, population
		, ISNULL(new_vaccinations,0) NewVaccinations
		, ISNULL(SUM(CONVERT(float,new_vaccinations))
			OVER (PARTITION BY (vacc.location) order by vacc.date),0) AS CurrentlyVaccinated
FROM
	CovidProject..CovidVaccinations vacc
		Join 
			CovidProject..CovidDeaths death
			ON 
				vacc.location=death.location
				AND vacc.date=death.date
WHERE
	vacc.continent is not null
)
SELECT 
	Country, Population
	, MAX(CurrentlyVaccinated) TotalNumberVaccinated
	, MAX(CurrentlyVaccinated)/Population*100 PercentageOfPopulationVaccinated
FROM
	DailyVaccNumbers
GROUP BY
	Country
	, Population
ORDER BY
	4 DESC

--Method 2: Using Temp Table
DROP TABLE IF EXISTS
	#DailyVaccNumbers
CREATE TABLE
	#DailyVaccNumbers
	(
	Country nvarchar(50)
	, Date datetime
	, Population Numeric
	, NewVaccinations Numeric
	, CurrentlyVaccinated Numeric
	)
INSERT INTO
	#DailyVaccNumbers
SELECT
	vacc.location
	, vacc.date
	, population
	, ISNULL(new_vaccinations,0) NewVaccinations
	, ISNULL(SUM(CONVERT(float,new_vaccinations))
		OVER (PARTITION BY (vacc.location) order by vacc.date),0) AS CurrentlyVaccinated
FROM
	CovidProject..CovidVaccinations vacc
		Join CovidProject..CovidDeaths death
			ON vacc.location=death.location
			AND vacc.date=death.date
WHERE
	vacc.continent is not null

SELECT
	Country
	, Population
	, MAX(CurrentlyVaccinated) TotalNumberVaccinated
	, MAX(CurrentlyVaccinated)/Population*100 PercentageOfPopulationVaccinated
FROM
	#DailyVaccNumbers
GROUP BY
	Country
	, Population
ORDER BY
	4 DESC

--Calculate Total Percentage of Population vaccinated By Country
SELECT
	vacc.location Country
	, SUM(CAST(new_vaccinations AS float)) NumberOfVaccinated
	, population Population
	, SUM(CAST(new_vaccinations AS float))/population*100 PercentageVaccinated
FROM
	CovidProject..CovidVaccinations vacc
		Join CovidProject..CovidDeaths death
			ON vacc.location=death.location
			AND vacc.date=death.date
WHERE
	vacc.continent is not null
GROUP BY
	vacc.location
	, population
ORDER BY
	4 DESC

--Creating View for Future Data Visualization
CREATE VIEW
	ViewDailyVaccNumbers
AS
SELECT
	vacc.location
	, vacc.date
	, population
	, ISNULL(new_vaccinations,0) NewVaccinations
	, ISNULL(SUM(CONVERT(float,new_vaccinations))
		OVER (PARTITION BY (vacc.location) order by vacc.date),0) AS CurrentlyVaccinated
FROM
	CovidProject..CovidVaccinations vacc
		Join CovidProject..CovidDeaths death
			ON vacc.location=death.location
			AND vacc.date=death.date
WHERE
	vacc.continent is not null

SELECT
	*
FROM
	ViewDailyVaccNumbers