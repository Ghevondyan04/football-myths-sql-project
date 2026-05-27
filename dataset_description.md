# Dataset Description

## Dataset Name

International Football Results from 1872 to 2017

## Dataset Source

The dataset was obtained from Kaggle:

https://www.kaggle.com/datasets/martj42/international-football-results-from-1872-to-2017

## Dataset Domain

The dataset belongs to the sports analytics domain. It contains historical international football match information.

## Purpose of Using This Dataset

This dataset was selected because it contains several related files that can be transformed into a relational database structure and analyzed using SQL.

The data is suitable for descriptive analysis of football-related questions and myths, such as:

- whether home teams always have a strong advantage;
- whether football is becoming lower-scoring over time;
- whether big wins are common;
- whether most goals happen in the final minutes;
- whether penalties and shootout order decide most outcomes.

## Main Files Used

### `results.csv`

This file contains match-level information.

Main variables include:

- match date
- home team
- away team
- home score
- away score
- tournament
- city
- country
- neutral venue indicator

This file is the main source for match-level analysis.

### `shootouts.csv`

This file contains penalty shootout information.

Main variables include:

- match date
- home team
- away team
- shootout winner
- first shooting team

This file is used to analyze penalty shootout outcomes.

### `goalscorers.csv`

This file contains goal-level information.

Main variables include:

- match date
- home team
- away team
- scoring team
- scorer name
- goal minute
- own goal indicator
- penalty indicator

This file is used for goal timing, penalty goal, own goal, and top scorer summaries.

### `former_names.csv`

This file contains historical team-name information.

It was reviewed as supporting information, but former names were not automatically remapped in the final pipeline in order to avoid historical misclassification.

## Main Entities Identified

The main entities in the dataset are:

- teams
- tournaments
- locations
- matches
- shootouts
- goalscorers

These entities were used to design the relational database schema.

## Analytical Value

The dataset allows meaningful SQL analysis because it supports:

- summary statistics;
- trend analysis by decade;
- grouped analysis by match result, tournament, team, and goal period;
- multi-table joins;
- team performance summaries;
- football myth evaluation using descriptive evidence.
