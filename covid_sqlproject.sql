SELECT *
FROM covid_death
ORDER BY 3,4

--Total cases vs total deaths

------First issue: Total cases was a different data type. I used ALTER TABLE and ALTER COLUMN to change data type.
--ALTER TABLE covid_death
--ALTER COLUMN total_cases int;

------Second issue: Integer math- running this code resulted in values of null or 0 in every row. I changed total_death to a float by multiplying by 1.0...
SELECT location, date, total_cases, total_deaths, ((total_deaths * 1.0)/total_cases) * 100 as DeathPercentage
FROM covid_death
WHERE location like '%states%'
ORDER BY 1,2

------...and here by using CAST

SELECT location, date, total_cases, total_deaths, (cast(total_deaths as float)/total_cases) * 100 as DeathPercentage
FROM covid_death
WHERE location like '%states%'
ORDER BY 1,2

--Looking at Total Cases vs Population

SELECT location, date, population, total_cases, ((total_cases * 1.0)/population) * 100 as InfectionPercentage
FROM covid_death
WHERE location like '%states%'
ORDER BY 1,2


--Looking at Countries with the highest population infection rate

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases * 1.0/population)) * 100 as PopulationPercentageInfected
FROM covid_death
--WHERE location like '%states%'
GROUP BY location, population
ORDER BY PopulationPercentageInfected DESC

--Showing countries with the highest population death count

SELECT location, MAX(total_deaths) as TotalDeathCount
FROM covid_death
WHERE continent IS NOT NULL
--WHERE location like '%states%'
GROUP BY location
ORDER BY TotalDeathCount DESC

--Broken down by continent


--looking at larger locations for testing later
--SELECT Location, MAX(total_deaths) as TotalDeathCount
--FROM covid_death
--WHERE continent IS NULL
----WHERE location like '%states%'
--GROUP BY Location
--ORDER BY TotalDeathCount DESC

SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM covid_death
WHERE continent IS not NULL
--WHERE location like '%states%'
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global numbers
------Third issue: Division by zero error- Used NULLIF to add a null value when a zero was in the new_cases column, also used CONVERT to change datatype

SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, (CONVERT(float, SUM(new_deaths))/NULLIF(SUM(new_cases), 0)) * 100 as DeathPercentage
FROM covid_death
--WHERE location like '%states%'
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinations
FROM covid_death as dea
JOIN covid_vaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

--Use a CTE

WITH PopVsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinations
FROM covid_death as dea
JOIN covid_vaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)

SELECT *, (CAST(RollingPeopleVaccinated as float)/population) * 100
FROM PopVsVac


-- Use a temp table

DROP TABLE IF EXISTS #PercentofPopulationVaccinated

CREATE TABLE #PercentofPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric)

INSERT INTO #PercentofPopulationVaccinated

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinations
FROM covid_death as dea
JOIN covid_vaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (CAST(RollingPeopleVaccinated as float)/population) * 100
FROM #PercentofPopulationVaccinated

--Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinations
FROM covid_death as dea
JOIN covid_vaccinations as vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated