--Targetting interesting topics
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [portfolio_project].[dbo].[CovidDeaths]
Order by 1,2

--Total cases vs Total deaths in Canada
SELECT
    location,
    date,
    total_cases,
    total_deaths,
    CAST((total_deaths * 100.0 / total_cases) AS DECIMAL(18, 4)) as DeathPercentage
FROM [portfolio_project].[dbo].[CovidDeaths]
WHERE location LIKE '%Canada%';


--Total cases vs Population 
SELECT location, date, population, total_cases, (CAST(total_cases AS DECIMAL(18, 4))/population)*100 as CovidPercentage
FROM [portfolio_project].[dbo].[CovidDeaths]
ORDER BY 1, 2

--Countries with Highest Infection Rate compared to Population 
SELECT
    location,
    population,
    MAX(total_cases) as HighestInfectionCount,
    MAX((CAST(total_cases AS DECIMAL(18, 4)) / population)) * 100 as CovidPercentage
FROM [portfolio_project].[dbo].[CovidDeaths]
GROUP BY location, population
ORDER BY CovidPercentage DESC;

--Countries with Highest Infection Rate compared to Population grouped by date
SELECT
    location,
    population,
	date,
    MAX(total_cases) as HighestInfectionCount,
    MAX((CAST(total_cases AS DECIMAL(18, 4)) / population)) * 100 as CovidPercentage
FROM [portfolio_project].[dbo].[CovidDeaths]
GROUP BY location, population,date
ORDER BY CovidPercentage DESC;

--Countries with highest death count according to continent
SELECT location, SUM(cast(new_deaths as int)) as TotalDeathCount
FROM [portfolio_project].[dbo].[CovidDeaths]
WHERE continent is null
and location not like '%income%'
and location not in ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount DESC

--Let's look at it globally
SELECT
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    CAST(SUM(new_deaths) AS DECIMAL(18, 4)) / SUM(new_cases) * 100 AS DeathPercentage
FROM [portfolio_project].[dbo].[CovidDeaths]
WHERE continent IS NOT NULL
ORDER BY 1, 2;

--joining two tables - vaccinations and deaths
SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,sum(vaccinations.new_vaccinations) OVER (Partition by deaths.location Order by deaths.location,deaths.date) as cumulative_count
FROM [portfolio_project].[dbo].[CovidDeaths] as deaths
JOIN [portfolio_project].[dbo].[CovidVaccinations] as vaccinations
ON deaths.location = vaccinations.location
AND deaths.date = vaccinations.date
WHERE deaths.continent is not null
And deaths.location like '%Canada%'
ORDER BY 2, 3

--Populations vs Vaccinations (cte)
With PopvsVac (continent, location, date, population, new_vaccinations, cumulative_count)
as
(SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,sum(vaccinations.new_vaccinations) OVER (Partition by deaths.location Order by deaths.location,deaths.date) as cumulative_count
FROM [portfolio_project].[dbo].[CovidDeaths] as deaths
JOIN [portfolio_project].[dbo].[CovidVaccinations] as vaccinations
ON deaths.location = vaccinations.location
AND deaths.date = vaccinations.date
WHERE deaths.continent is not null
)
select *,(cumulative_count/population)*100 from PopvsVac;

--Using temp table
DROP Table if exists #PercentPopulationVaccinated

Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
cumulative_count numeric
)
Insert into #PercentPopulationVaccinated

SELECT deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations,sum(vaccinations.new_vaccinations) OVER (Partition by deaths.location Order by deaths.location,deaths.date) as cumulative_count
FROM [portfolio_project].[dbo].[CovidDeaths] as deaths
JOIN [portfolio_project].[dbo].[CovidVaccinations] as vaccinations
ON deaths.location = vaccinations.location
AND deaths.date = vaccinations.date
WHERE deaths.continent is not null

SELECT *, (cumulative_count/population)*100 FROM #PercentPopulationVaccinated