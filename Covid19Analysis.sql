--Data exploration:
SELECT * 
FROM CovidVaccinations
ORDER BY 3,4

--SELECT *
--FROM CovidDeaths
--ORDER BY 3,4

--Select data that we are going to use:
SELECT [location], [date],total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2


-- looking at total cases vs total deaths:
-- shows likelihood of dying if you contract covid in SA
SELECT [location], [date],total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE [location] like '%south%africa'
ORDER BY 1,2


--looking at total cases vs population:
--shows what % of population got covid
SELECT [location], [date], total_cases, total_deaths, population, (total_cases/population)*100 as CasePercentage
FROM CovidDeaths
WHERE [location] like '%south%africa'
ORDER BY 1,2

-- which countries have highest infection rate compared to  population
SELECT [location], MAX(total_cases) as HighestInfectionCount, population, MAX((total_cases/population))*100 as InfectedPercentage
FROM CovidDeaths
--WHERE [location] like '%south%africa'
GROUP BY population, [location]
ORDER BY InfectedPercentage DESC

-- Break things down by continent ----

-- show the countries with the highest death count per population
SELECT [continent], MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
--WHERE [location] like '%south%africa'
WHERE continent is NOT NULL
GROUP BY [continent]
ORDER BY TotalDeathCount DESC

-- this is the correct way
-- SELECT [location], MAX(CAST(total_deaths as int)) as TotalDeathCount
-- FROM CovidDeaths
-- --WHERE [location] like '%south%africa'
-- WHERE continent is NULL
-- GROUP BY [location]
-- ORDER BY TotalDeathCount DESC

-- showing the continents with the highest death count
SELECT [continent], MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths
--WHERE [location] like '%south%africa'
WHERE continent is NOT NULL
GROUP BY [continent]
ORDER BY TotalDeathCount DESC

-- Global numbers:
SELECT [date],SUM(new_cases) as TotalCases, SUM(CAST(new_deaths as int)) as TotalDeaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE continent is NOT NULL
GROUP by [date]
ORDER BY 1,2

SELECT SUM(new_cases) as TotalCases, SUM(CAST(new_deaths as int)) as TotalDeaths, SUM(CAST(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1,2

----------------------------------------------------------
-- looking at total vaccination vs population
SELECT dea.continent, dea.[location], dea.[date], dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date] 
    WHERE dea.continent is NOT NULL
ORDER BY 2,3

--method 1: use CTE
WITH PopVSVac (Continent,Location,Date,Population, New_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.[location], dea.[date], dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, 
dea.date) as RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
    ON dea.[location] = vac.[location]
    AND dea.[date] = vac.[date] 
    WHERE dea.continent is NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopVSVac

--method 2: TEMP TABLE
DROP TABLE PopulationVaccinatedPercent
DROP TABLE PercentPopulationVaccinated

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- creating View to store data for later visualisations
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

