# COG Communes

- [README en anglais](https://github.com/sfaut/data-cog-cities/tree/master/README.md)
- [README en français](https://github.com/sfaut/data-cog-cities/tree/master/README_FR.md)
- [ELT SQL et données 2025](https://github.com/sfaut/data-cog-cities/tree/master/v2025/elt.sql)

## Présentation

L'<abbr title="Institut National de la Statistique et des Études Économiques">INSEE</abbr> propose des fichiers annuels relatifs aux communes, cantons, arrondissements, collectivités territoriales exerçant des compétences départementales, départements, régions, ainsi qu'aux pays et territoires étrangers, via le Code Officiel Géographique (<abbr title="Code Officiel Géographique">COG</abbr>).

Ce dépôt fournit le fichier des communes, enrichi par des informations sur les cantons, arrondissements, départements, collectivités territoriales et régions aux formats DuckDB, CSV, ND-JSON et Parquet.

## Millésime 2025

Cette version de la base contient :
- Une table `cog.city` de 37 548 communes, dont 34 875 communes (`COM`), 2 152 communes déléguées (`COMD`), 476 communes associées (`COMA`) et 45 arrondissements municipaux (`ARM`)
- Une table `cog.city_unique` excluant les communes déléguées afin d'assurer l'unicité sur le code commune INSEE
- Les données hiérarchiques mises à plat (régions, départements, collectivités territoriales, arrondissements, cantons, types de noms)
- Les données hiérarchiques renseignées pour les communes associées et les communes déléguées

## Exemple

```sql
pivot (
  from 'https://github.com/sfaut/data-cog-cities/raw/refs/heads/master/v2025/cog-cities@2025.csv'
  select all department_identity as "Département", type_code
  where region_name = 'Île-de-France'
)
on type_code
using count(*)
group by "Département"
order by 1 asc;
```

Produit :

| Département            | ARM | COM | COMA | COMD |
|-----------------------:|----:|----:|-----:|-----:|
| 75 – Paris             |  20 |   1 |    0 |    0 |
| 77 – Seine-et-Marne    |   0 | 507 |    7 |    7 |
| 78 – Yvelines          |   0 | 259 |    0 |    3 |
| 91 – Essonne           |   0 | 194 |    0 |    2 |
| 92 – Hauts-de-Seine    |   0 |  36 |    0 |    0 |
| 93 – Seine-Saint-Denis |   0 |  39 |    0 |    2 |
| 94 – Val-de-Marne      |   0 |  47 |    0 |    0 |
| 95 – Val-d'Oise        |   0 | 183 |    0 |    0 |

## Schéma de `cog.city`

`cog.city_unique` est identique, à l'exception de la colonne `key` inexistante.

| Colonne                   | Type        | Description                                                                                           |
|--------------------------:|------------:|-------------------------------------------------------------------------------------------------------|
| 🔑 `key`                 | `VARCHAR`   | Clef primaire composée de `code` et `type_code`, inexistante sur `cog.city_unique`                     |
| `code`                    | `VARCHAR`   | Code INSEE de la commune, ex. *17300*, clef primaire de `cog.city_unique`                             |
| 🔗 `parent_code`         | `VARCHAR`   | Code INSEE de la commune mère, pour les `COMA`, `COMD` et `ARM`                                       |
| 🔗 `type_code`           | `VARCHAR`   | `COM`, `COMA`, `COMD` ou `ARM`                                                                        |
| `type_name`               | `VARCHAR`   | Type en clair, ex. *Commune*                                                                          |
| `name`                    | `VARCHAR`   | Nom de la commune, ex. *La Rochelle*                                                                  |
| `single_name`             | `VARCHAR`   | Nom de la commune sans article, ex. *Rochelle*                                                        |
| `simple_name`             | `VARCHAR`   | Nom de la commune sans article et sans accentuation, ex. *ROCHELLE*                                   |
| `group_name`              | `VARCHAR`   | Groupe nominal du nom de la commune, ex. *Commune de La Rochelle*                                     |
| 🔗 `tncc_id`             | `UTINYINT`  | ID du type de nom                                                                                     |
| `tncc_article`            | `VARCHAR`   | Article, ex. *La* pour *La Rochelle*                                                                  |
| `tncc_preposition`        | `VARCHAR`   | Préposition, ex. *de La* pour *Commune de La Rochelle*                                                |
| 🔗 `region_code`         | `VARCHAR`   | Code INSEE de la région, ex. *75*                                                                     |
| `region_name`             | `VARCHAR`   | Nom de la région, ex. *Nouvelle-Aquitaine*                                                            |
| `region_identity`         | `VARCHAR`   | Code et nom de la région, ex. *75 – Nouvelle-Aquitaine*                                               |
| 🔗 `department_code`     | `VARCHAR`   | Code INSEE du département, ex. *17*                                                                   |
| `department_name`         | `VARCHAR`   | Nom du département, ex. *Charente-Maritime*                                                           |
| `department_identity`     | `VARCHAR`   | Code et nom du département, ex. *17 – Charente-Maritime*                                              |
| 🔗 `collectivity_code`   | `VARCHAR`   | Code de la collectivité territoriale, ex. *17D*                                                       |
| `collectivity_name`       | `VARCHAR`   | Nom de la collectivité territoriale, ex. *Conseil départemental de La Charente-Maritime*              |
| `collectivity_identity`   | `VARCHAR`   | Code et nom de la colletivité territoriale, ex. *17D – Conseil départemental de La Charente-Maritime* |
| 🔗 `arrondissement_code` | `VARCHAR`   | Code de l'arrondissement, ex. *173*                                                                   |
| `arrondissement_name`     | `VARCHAR`   | Nom de l'arrondissement, ex. *La Rochelle*                                                            |
| `arrondissement_identity` | `VARCHAR`   | Code et nom de l'arrondissement, ex. *173 – La Rochelle*                                              |
| 🔗 `canton_code`         | `VARCHAR`   | Code du canton, ex. *1799*                                                                            |
| `canton_name`             | `VARCHAR`   | Nom du canton, ex. *La Rochelle*                                                                      |
| `canton_identity`         | `VARCHAR`   | Code et nom du canton, ex. *1799 – La Rochelle*                                                       |
| `version`                 | `USMALLINT` | Version du COG, ex. *2025*                                                                            |

## Traitements

- Les données hiérarchiques sont mises à plat et développées (régions, départements, collectivité territoriale, arrondissement, canton, type de nom)
- Les données hiérarchiques initialement absentes pour les communes associées et les communes déléguées sont valorisées

## Ressources

- https://www.insee.fr/fr/information/8391822
- https://www.insee.fr/fr/information/8377252
- https://www.insee.fr/fr/information/8377162
