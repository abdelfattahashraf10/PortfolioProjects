/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location like '%states%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where location like '%states%'
order by 1,2


-- Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) AS HighestInfectionCount,
	ROUND(Max((total_cases/population))*100, 2 )AS PercentPopulationInfected
From PortfolioProject..CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT
		--WHERE continent is not null-

	-- data overview 
SELECT location, continent, date, population, total_cases, CAST(total_deaths AS INT) AS TotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, continent, date, population, total_cases, total_deaths
ORDER BY 1, 2

	-- the Highest Deaths Count for each continent
Select continent, MAX(cast(Total_deaths AS int)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc

	-- the Deaths Count for each Country(location)
Select location, population, MAX(total_cases) AS total_cases ,MAX(cast(Total_deaths AS INT)) AS TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by location,population
order by TotalDeathCount desc

	-- Showing country(location) with the Highest Death Count per Population
SELECT location,  population, MAX(CAST(total_deaths AS INT)) AS total_deaths, 
	ROUND((MAX(CAST(total_deaths AS INT))/population)*100, 3) AS DeathCountpercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY DeathCountpercentage DESC

	-- Showing continent with the Highest Death Count per Population
SELECT continent,   MAX(CAST(total_deaths AS INT)) AS total_deaths 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_deaths DESC

--GLOBAL NUMBERS

Select location, date, MAX(total_cases) AS MaxTotalCases--, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
From PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date, location
order by 1, 2 
--								==
Select location, date, SUM(new_cases) AS SumNewCases
From PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date, location
order by 1, 2



Select  date, SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
	ROUND((SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100, 3) AS DeathPercentage
From PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
order by 1, 2

-- To get the Total Cases VS Deaths and DeathsPercentage
Select SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS INT))  TotalDeaths,
	ROUND((SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100, 3)  DeathPercentage
From PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
order by 1, 2
--------------------------------------------------------------------------------


-- Looking at Total population vs Vaccinations (How many people in world have been vaccinated)
SELECT dea.continent, dea.location, dea.date, population, new_vaccinations
FROM PortfolioProject..CovidDeaths dea
JOIN  PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
ORDER BY  2, 3

-- How Many People were VACCINATED -one shot-
SELECT dea.location, 
	SUM(CONVERT(INT, new_vaccinations )) AllVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN  PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
GROUP BY dea.location 
ORDER BY  1

-- How Many People were VACCINATED (partition by -day by day-) 
SELECT dea.continent, dea.location, dea.date, population, new_vaccinations,
	SUM(CONVERT(INT, new_vaccinations )) OVER (PARTITION BY dea.location 
		ORDER BY dea.location, dea.date) RollingPeaopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN  PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
ORDER BY  2, 3

-- Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, population, new_vaccinations,
	SUM(CONVERT(INT, new_vaccinations )) OVER (PARTITION BY dea.location 
		ORDER BY dea.location, dea.date) RollingPeaopleVaccinated, 
	(RollingPeaopleVaccinated/population)*100 -- WRONG
FROM PortfolioProject..CovidDeaths dea         -- cuz we CAN'T use the Aliased Column -in SELECT statement- at a Function 
JOIN  PortfolioProject..CovidVaccinations vac									-- in the SAME SELECT statement
	ON dea.location = vac.location												-- SO we gonna use TEMP_TABLE or CTE 
	AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
ORDER BY  2, 3

									--USE CTE
WITH PopvsVac (Continent, Location, Date, Population, new_vaccinations, RollingPeaopleVaccinated)
AS 
(SELECT dea.continent, dea.location, dea.date, population, new_vaccinations,
	SUM(CONVERT(INT, new_vaccinations )) OVER (PARTITION BY dea.location 
		ORDER BY dea.location, dea.date) RollingPeaopleVaccinated
	--(RollingPeaopleVaccinated/population)*100 
FROM PortfolioProject..CovidDeaths dea         
JOIN  PortfolioProject..CovidVaccinations vac									
	ON dea.location = vac.location												
	AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, ROUND((RollingPeaopleVaccinated/population)*100, 3) VaccPercent_CTE
FROM PopvsVac
ORDER BY  2, 3

									-- TEMP TABLE

DROP TABLE IF EXISTS #PercentPopulationVaccinated --for multible runs
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeaopleVaccinated numeric
)


INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, population, new_vaccinations,
	SUM(CONVERT(INT, new_vaccinations )) OVER (PARTITION BY dea.location 
		ORDER BY dea.location, dea.date) RollingPeaopleVaccinated
	--(RollingPeaopleVaccinated/population)*100 
FROM PortfolioProject..CovidDeaths dea         
JOIN  PortfolioProject..CovidVaccinations vac									
	ON dea.location = vac.location												
	AND dea.date =vac.date
WHERE dea.continent IS NOT NULL
								
SELECT *, ROUND((RollingPeaopleVaccinated/population)*100, 3) VaccPercent_TEMP
FROM #PercentPopulationVaccinated
ORDER BY  2, 3




-- Creating View to store data for later Visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, population, new_vaccinations,
	SUM(CONVERT(INT, new_vaccinations )) OVER (PARTITION BY dea.location 
		ORDER BY dea.location, dea.date) RollingPeaopleVaccinated
	--(RollingPeaopleVaccinated/population)*100 
FROM PortfolioProject..CovidDeaths dea         
JOIN  PortfolioProject..CovidVaccinations vac									
	ON dea.location = vac.location												
	AND dea.date =vac.date
WHERE dea.continent IS NOT NULL

SELECT *
FROM PercentPopulationVaccinated
ORDER BY 2, 3
