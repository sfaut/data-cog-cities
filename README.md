# COG Cities

- [README in English](https://github.com/sfaut/data-cog-cities/tree/master/README.md)
- [README in French](https://github.com/sfaut/data-cog-cities/tree/master/README_FR.md)
- [ELT SQL and 2025 Data](https://github.com/sfaut/data-cog-cities/tree/master/v2025/elt.sql)

## Overview

The <abbr title="National Institute of Statistics and Economic Studies">INSEE</abbr>
provides annual files related to cities, cantons, arrondissements,
territorial collectivities with departmental powers, departments, regions,
as well as foreign countries and territories,
through the Official Geographic Code (<abbr title="Official Geographic Code">COG</abbr>).

This repository provides the cities file, enriched with information on cantons, arrondissements,
departments, territorial collectivities, and regions in DuckDB, CSV, ND-JSON, and Parquet formats.

## 2025 Edition

This version of the database contains:
- A `cog.city` table with 37,548 cities, including 34,875 cities (`COM`), 2,152 delegated cities (`COMD`), 476 associated cities (`COMA`), and 45 municipal arrondissements (`ARM`)
- A `cog.city_unique` table excluding delegated cities to ensure uniqueness on the INSEE city code
- Flattened hierarchical data (regions, departments, territorial collectivities, arrondissements, cantons, name types)
- Hierarchical data populated for associated and delegated cities

## Example

```sql
pivot (
  from 'https://github.com/sfaut/data-cog-cities/raw/refs/heads/master/v2025/cog-cities@2025.csv'
  select all department_identity as "Department", type_code
  where region_name = 'Île-de-France'
)
on type_code
using count(*)
group by "Department"
order by 1 asc;
```

Output:

| Department             | ARM | COM | COMA | COMD |
|-----------------------:|----:|----:|-----:|-----:|
| 75 – Paris             |  20 |   1 |    0 |    0 |
| 77 – Seine-et-Marne    |   0 | 507 |    7 |    7 |
| 78 – Yvelines          |   0 | 259 |    0 |    3 |
| 91 – Essonne           |   0 | 194 |    0 |    2 |
| 92 – Hauts-de-Seine    |   0 |  36 |    0 |    0 |
| 93 – Seine-Saint-Denis |   0 |  39 |    0 |    2 |
| 94 – Val-de-Marne      |   0 |  47 |    0 |    0 |
| 95 – Val-d’Oise        |   0 | 183 |    0 |    0 |

## Schema of `cog.city`

`cog.city_unique` is identical, except for the `key` column, which is absent.

| Column                    | Type        | Description                                                                                           |
|--------------------------:|------------:|-------------------------------------------------------------------------------------------------------|
| 🔑 `key`                 | `VARCHAR`   | Primary key composed of `code` and `type_code`, absent in `cog.city_unique`                           |
| `code`                    | `VARCHAR`   | INSEE city code, e.g. *17300*, primary key of `cog.city_unique`                                       |
| 🔗 `parent_code`         | `VARCHAR`   | INSEE code of the parent city, for `COMA`, `COMD`, and `ARM`                                          |
| 🔗 `type_code`           | `VARCHAR`   | `COM`, `COMA`, `COMD`, or `ARM`                                                                       |
| `type_name`               | `VARCHAR`   | Type in plain text, e.g. *Commune*                                                                       |
| `name`                    | `VARCHAR`   | City name, e.g. *La Rochelle*                                                                         |
| `single_name`             | `VARCHAR`   | City name without article, e.g. *Rochelle*                                                            |
| `simple_name`             | `VARCHAR`   | City name without article or accents, e.g. *ROCHELLE*                                                 |
| `group_name`              | `VARCHAR`   | Nominal group of the city name, e.g. *Commune de La Rochelle*                                         |
| 🔗 `tncc_id`             | `UTINYINT`  | Name type ID                                                                                          |
| `tncc_article`            | `VARCHAR`   | Article, e.g. *La* for *La Rochelle*                                                                  |
| `tncc_preposition`        | `VARCHAR`   | Preposition, e.g. *of La* for *Commune de La Rochelle*                                                |
| 🔗 `region_code`         | `VARCHAR`   | INSEE region code, e.g. *75*                                                                          |
| `region_name`             | `VARCHAR`   | Region name, e.g. *Nouvelle-Aquitaine*                                                                |
| `region_identity`         | `VARCHAR`   | Region code and name, e.g. *75 – Nouvelle-Aquitaine*                                                  |
| 🔗 `department_code`     | `VARCHAR`   | INSEE department code, e.g. *17*                                                                      |
| `department_name`         | `VARCHAR`   | Department name, e.g. *Charente-Maritime*                                                             |
| `department_identity`     | `VARCHAR`   | Department code and name, e.g. *17 – Charente-Maritime*                                               |
| 🔗 `collectivity_code`   | `VARCHAR`   | Territorial collectivity code, e.g. *17D*                                                             |
| `collectivity_name`       | `VARCHAR`   | Territorial collectivity name, e.g. *Conseil départemental de La Charente-Maritime*                   |
| `collectivity_identity`   | `VARCHAR`   | Collectivity code and name, e.g. *17D – Conseil départemental de La Charente-Maritime*                |
| 🔗 `arrondissement_code` | `VARCHAR`   | Arrondissement code, e.g. *173*                                                                       |
| `arrondissement_name`     | `VARCHAR`   | Arrondissement name, e.g. *La Rochelle*                                                               |
| `arrondissement_identity` | `VARCHAR`   | Arrondissement code and name, e.g. *173 – La Rochelle*                                                |
| 🔗 `canton_code`         | `VARCHAR`   | Canton code, e.g. *1799*                                                                              |
| `canton_name`             | `VARCHAR`   | Canton name, e.g. *La Rochelle*                                                                       |
| `canton_identity`         | `VARCHAR`   | Canton code and name, e.g. *1799 – La Rochelle*                                                       |
| `version`                 | `USMALLINT` | COG version, e.g. *2025*                                                                              |

## Processing

- Hierarchical data is flattened and expanded (regions, departments, territorial collectivities, arrondissements, cantons, name types)
- Hierarchical data initially missing for associated and delegated cities is populated

## Resources

- https://www.insee.fr/fr/information/8391822
- https://www.insee.fr/fr/information/8377252
- https://www.insee.fr/fr/information/8377162
