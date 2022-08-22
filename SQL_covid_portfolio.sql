--select * from PortfolioProject..CovidDeaths$ where continent is not null order by 3,4

--select * from PortfolioProject..CovidVaccination$ order by 3,4

--Select Data that we are going to use

--select location, date, total_cases, new_cases, total_deaths, population from PortfolioProject..CovidDeaths$ order by 1,2

--Looking ata Total cases vs total deaths
--shows likelihood of dying if you contract covid in your country
--select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage 
--from PortfolioProject..CovidDeaths$ 
--where location like '%states%' and continent is not null 
--order by 1,2

-- looking at Total Cases vs Population
-- shows what percentage of population got Covid
--select location, date, total_cases, population, (total_cases/population)*100 as case_percentage 
--from PortfolioProject..CovidDeaths$ 
--where continent is not null 
--order by date 

-- Looking at countries with highest infection rate compared to population
--SELECT location, population, MAX(total_cases) as highest_infection_countries, MAX((total_cases/population))*100 as percentage_population_infected
--FROM PortfolioProject..CovidDeaths$ 
--WHERE continent is not null 
--GROUP BY location, population
--ORDER BY percentage_population_infected desc

-- showing countries with highest death count population
--SELECT location, MAX(cast(total_deaths as int)) as total_death_count
--FROM PortfolioProject..CovidDeaths$ 
--WHERE continent is not null 
--GROUP BY location, population
--ORDER BY total_death_count desc

--breaking down the continent
--showing continents with the highest death count per population
--SELECT continent, MAX(cast(total_deaths as int)) as total_death_count
--FROM PortfolioProject..CovidDeaths$ 
--WHERE continent is not null 
--GROUP BY continent
--ORDER BY total_death_count desc

-- global numbers 
--1
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 as death_percentage
FROM PortfolioProject..CovidDeaths$ 
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2

--2
--we take these out as they are not included in the above querries and want to stay consistent 
--European Union is part of Europe

SELECT location, SUM(CAST(new_deaths AS int)) as total_death_count
FROM PortfolioProject..CovidDeaths$
WHERE continent is null
AND location not in ('World', 'European Union', 'International')
GROUP BY location
ORDER BY total_death_count DESC


--3
SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 AS percent_population_infected
FROM PortfolioProject..CovidDeaths$
GROUP BY location, population
ORDER BY percent_population_infected DESC

--4
SELECT location, population, date, MAX(total_cases) as highest_infection_count, MAX((total_cases/population))*100 AS percent_population_infected
FROM PortfolioProject..CovidDeaths$
GROUP BY location, population, date
ORDER BY percent_population_infected DESC


-- looking at total population vs vaccination
--SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
--SUM(CONVERT(int, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated,
--(rolling_people_vaccinated/dea.population)
--FROM PortfolioProject..CovidDeaths$ dea
--JOIN PortfolioProject..CovidVaccinations$ vac ON dea.location = vac.location and dea.date = vac.date
--WHERE dea.continent is not null
--ORDER BY 2,3

-- Use CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccination, rolling_people_vaccinated) 
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations AS bigint)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)

SELECT *, (rolling_people_vaccinated/population)*100
FROM PopvsVac


--temp table
DROP TABLE IF exists #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric, 
New_Vaccinations numeric,
rolling_people_vaccinated numeric
)

INSERT INTO #PercentagePopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (rolling_people_vaccinated/population)*100
FROM #PercentagePopulationVaccinated


-- creating view for visualization


CREATE VIEW PercentagePopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER(PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_people_vaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac ON dea.location = vac.location and dea.date = vac.date
WHERE dea.continent is not null