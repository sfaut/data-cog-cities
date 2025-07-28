-- COG Communes
-- Create tables memory.cog.city and memory.cog.city_unique tables from French Code Officiel Géographique
-- sfaut <sebastien.faut@gmail.com>
-- 2025-07-27
-- DuckDB 1.3.1

-- Execute in the directory where you want to save files, with DuckDB CLI :
-- D .cd /path/to/dir
-- or update this script (see last lines)

install httpfs;
load httpfs;

create schema if not exists memory.cog;

use memory.cog;

create or replace table city as
from 'https://www.insee.fr/fr/statistiques/fichier/8377162/v_commune_2025.csv' as c
inner join 'https://github.com/sfaut/data-cog-tncc/raw/refs/heads/master/data/cog-tncc.csv' as t on c.TNCC = t.id
select all
  c.COM || '/' || c.TYPECOM as key,
  c.COM as code,
  c.TYPECOM as type_code,
  case c.TYPECOM
    when 'COM' then 'Commune'
    when 'COMA'	then 'Commune associée'
    when 'COMD'	then 'Commune déléguée'
    when 'ARM' then 'Arrondissement municipal'
  end as type_name,
  coalesce(c.COMPARENT, '') as parent_code,
  c.LIBELLE as name, -- Nom avec article
  c.NCCENR as single_name, -- Nom sans article, utile pour construire le nom avec charnière
  c.NCC as simple_name, -- Nom sans article et sans accentuation, tirets, apostrophes, ...
  'Commune ' || t.preposition || c.NCCENR as group_name,
  cast(c.TNCC as utinyint) as tncc_id,
  coalesce(t.article, '') as tncc_article,
  t.preposition as tncc_preposition,
  lpad(cast(c.REG as varchar), 2, '0') as region_code,
  '' as region_name,
  '' as region_identity,
  c.DEP as department_code,
  '' as department_name,
  '' as department_identity,
  c.CTCD as collectivity_code, -- Code de la collectivité territoriale ayant les compétences départementales
  '' as collectivity_name,
  '' as collectivity_identity,
  coalesce(c.ARR, '') as arrondissement_code, -- Pas d'arrondissement en outre-mer
  '' as arrondissement_name,
  '' as arrondissement_identity,
  coalesce(c.CAN, '') as canton_code, -- Pas de canton en outre-mer
  '' as canton_name,
  '' as canton_identity,
  cast(2025 as usmallint) as version,
;

-- Hydrate COMA and COMD cities with missing hierarchy data
update cog.city as c
set
  region_code = (select all region_code from cog.city where code = c.parent_code and type_code = 'COM'),
  department_code = (select all department_code from cog.city where code = c.parent_code and type_code = 'COM'),
  collectivity_code = (select all collectivity_code from cog.city where code = c.parent_code and type_code = 'COM'),
  arrondissement_code = (select all arrondissement_code from cog.city where code = c.parent_code and type_code = 'COM'),
  canton_code = (select all canton_code from cog.city where code = c.parent_code and type_code = 'COM'),
where parent_code <> '';

-- Update cog.city model
alter table cog.city alter column code set not null;
alter table cog.city alter column type_code set not null;
alter table cog.city alter column type_name set not null;
alter table cog.city alter column parent_code set not null;
alter table cog.city alter column name set not null;
alter table cog.city alter column single_name set not null;
alter table cog.city alter column simple_name set not null;
alter table cog.city alter column group_name set not null;
alter table cog.city alter column tncc_id set not null;
alter table cog.city alter column tncc_article set not null;
alter table cog.city alter column tncc_preposition set not null;
alter table cog.city alter column region_code set not null;
alter table cog.city alter column region_name set not null;
alter table cog.city alter column region_identity set not null;
alter table cog.city alter column department_code set not null;
alter table cog.city alter column department_name set not null;
alter table cog.city alter column department_identity set not null;
alter table cog.city alter column collectivity_code set not null;
alter table cog.city alter column collectivity_name set not null;
alter table cog.city alter column collectivity_identity set not null;
alter table cog.city alter column arrondissement_code set not null;
alter table cog.city alter column arrondissement_name set not null;
alter table cog.city alter column arrondissement_identity set not null;
alter table cog.city alter column canton_code set not null;
alter table cog.city alter column canton_name set not null;
alter table cog.city alter column canton_identity set not null;
alter table cog.city alter column version set not null;

alter table cog.city add primary key (key);

-- Add region data
update cog.city as c
set
  region_name = r.LIBELLE,
  region_identity = r.REG || ' – ' || r.LIBELLE,
from 'https://www.insee.fr/fr/statistiques/fichier/8377162/v_region_2025.csv' as r
where c.region_code = r.REG;

-- Add department data
update cog.city as c
set
  department_name = d.LIBELLE,
  department_identity = d.DEP || ' – ' || d.LIBELLE,
from 'https://www.insee.fr/fr/statistiques/fichier/8377162/v_departement_2025.csv' as d
where c.department_code = d.DEP;

-- Add collectivity data
update cog.city as c
set
  collectivity_name = co.LIBELLE,
  collectivity_identity = co.CTCD || ' – ' || co.LIBELLE,
from 'https://www.insee.fr/fr/statistiques/fichier/8377162/v_ctcd_2025.csv' as co
where c.collectivity_code = co.CTCD;

-- Add arrondissement data
update cog.city as c
set
  arrondissement_name = a.LIBELLE,
  arrondissement_identity = a.ARR || ' – ' || a.LIBELLE,
from 'https://www.insee.fr/fr/statistiques/fichier/8377162/v_arrondissement_2025.csv' as a
where c.arrondissement_code = a.ARR;

-- Add canton data
update cog.city as c
set
  canton_name = ca.LIBELLE,
  canton_identity = ca.CAN || ' – ' || ca.LIBELLE,
from 'https://www.insee.fr/fr/statistiques/fichier/8377162/v_canton_2025.csv' as ca
where c.canton_code = ca.CAN;

-- Make unique code data
create or replace table cog.city_unique as
select all * exclude (key)
from cog.city
where type_code <> 'COMD';

-- Update cog.city_unique_unique model
alter table cog.city_unique alter column code set not null;
alter table cog.city_unique alter column parent_code set not null;
alter table cog.city_unique alter column type_code set not null;
alter table cog.city_unique alter column type_name set not null;
alter table cog.city_unique alter column name set not null;
alter table cog.city_unique alter column single_name set not null;
alter table cog.city_unique alter column simple_name set not null;
alter table cog.city_unique alter column tncc_id set not null;
alter table cog.city_unique alter column tncc_article set not null;
alter table cog.city_unique alter column tncc_preposition set not null;
alter table cog.city_unique alter column region_code set not null;
alter table cog.city_unique alter column region_name set not null;
alter table cog.city_unique alter column region_identity set not null;
alter table cog.city_unique alter column department_code set not null;
alter table cog.city_unique alter column department_name set not null;
alter table cog.city_unique alter column department_identity set not null;
alter table cog.city_unique alter column collectivity_code set not null;
alter table cog.city_unique alter column collectivity_name set not null;
alter table cog.city_unique alter column collectivity_identity set not null;
alter table cog.city_unique alter column arrondissement_code set not null;
alter table cog.city_unique alter column arrondissement_name set not null;
alter table cog.city_unique alter column arrondissement_identity set not null;
alter table cog.city_unique alter column canton_code set not null;
alter table cog.city_unique alter column canton_name set not null;
alter table cog.city_unique alter column canton_identity set not null;
alter table cog.city_unique alter column version set not null;

alter table cog.city_unique add primary key (code);

-- Create data files
copy cog.city to 'cog-cities@2025.csv';
copy cog.city to 'cog-cities@2025.ndjson';
copy cog.city to 'cog-cities@2025.parquet';
copy cog.city_unique to 'cog-cities-unique@2025.csv';
copy cog.city_unique to 'cog-cities-unique@2025.ndjson';
copy cog.city_unique to 'cog-cities-unique@2025.parquet';

attach 'cog-cities@2025.duckdb' as cog_city_save;
copy from database memory to cog_city_save;

detach cog_city_save;
