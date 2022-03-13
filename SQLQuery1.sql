--Exploration des donn�es Covid-19

SELECT *
FROM Portfolio_project..covid_death_data
WHERE continent is not null
ORDER BY date, total_cases

SELECT *
FROM Portfolio_project..covid_death_data
WHERE location = 'France'
ORDER BY date, population

-- Selectionner les variables n�cessaires pour la premi�re exploration des donn�es

Select location, date, total_cases, new_cases, total_deaths, population
From Portfolio_project..covid_death_data
Where continent is not null 
and total_deaths is not null
order by 1,2


-- Total Cases vs Total Deaths
-- Nombre de d�c�s en % parmi les personnes contamin�es en France 
Select location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From Portfolio_project..covid_death_data
Where location = 'France'
and continent is not null
and total_deaths is not null
order by date


-- Total Cases vs Population
-- Proportion des personnes contamin�es dans chaque pays 

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From Portfolio_project..covid_death_data
where total_cases is not NULL
order by 2,4


-- Pays avec le taux de contamination le plus �lev�

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From Portfolio_project..covid_death_data
Group by Location, Population
order by PercentPopulationInfected desc


-- Pays avec le taux de d�c�s le plus �lev�  
--(on utilise la fonction cast pour convertir la variable total_death (charact�re) en num�rique)

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From Portfolio_project..covid_death_data
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- REPARTITION PAR CONTINENT

-- Continents avec le taux de d�c�s le plus �lev� 

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From Portfolio_project..covid_death_data
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- CHIFFRES GLOBALS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Portfolio_project..covid_death_data
where continent is not null 
order by 1,2

--Tri�s par dates
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From Portfolio_project..covid_death_data
where continent is not NULL
Group By date
order by 1,2

----------------------------------------------------

-- Total Population vs Vaccinations
-- Proportion de la population vaccin�e

Select death.continent, death.location, death.date, death.population, vaccin.new_vaccinations
, SUM(CONVERT(bigint,vaccin.new_vaccinations)) OVER (Partition by death.Location Order by death.location, death.Date) as RollingPeopleVaccinated
--(RollingPeopleVaccinated/population)*100 as PercRollingPeopleVacc
From Portfolio_project..covid_death_data as death
Join Portfolio_project..vaccin_covid as vaccin
	On death.location = vaccin.location
	and death.date = vaccin.date
where death.continent is not null  and new_vaccinations is not NULL
order by 2,3


-- Fusionner les deux tables

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio_project..covid_death_data dea
Join Portfolio_project..vaccin_covid vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null )
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 as PercRollingPeopleVac
From PopvsVac



-- Cr�er une table avec les donn�es pr�c�dantes 

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric,
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio_project..covid_death_data dea
Join Portfolio_project..vaccin_covid vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Cr�er une vue de la table

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Portfolio_project..covid_death_data dea
Join Portfolio_project..vaccin_covid vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 