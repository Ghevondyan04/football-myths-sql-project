# Football Myths Descriptive Analysis Project

## Why We Chose This Dataset

We chose this football dataset because it is easy to understand, even for people who are not experts in data analysis. Football is familiar to many people, so the results are easier to explain and discuss.

Another reason we selected this dataset is that it contains several related files. These files include match results, teams, tournaments, penalty shootouts, goalscorers, and former team names. Because of this, the dataset was a good fit for building a relational database.

The dataset also allowed us to explore simple but interesting questions. For example, we could check whether home teams really win most of the time, whether football is becoming less exciting because of fewer goals, or whether most goals are scored near the end of the match.

---

## Project Overview

This project is a data ingestion and descriptive analysis project based on international football match data.

The main purpose of the project is to take raw football data, clean it, load it into a relational database, and then use SQL queries to create useful summary tables. These summary tables help us examine common football myths, such as:

- Home teams always win.
- Football is becoming boring because fewer goals are being scored.
- Big wins happen very often.
- Most goals are scored in the final minutes.
- Penalties and shootout order decide everything.

This project uses descriptive analysis only. That means we summarize and describe the data, but we do not perform formal statistical hypothesis testing.

A correct way to describe the findings is:

> The descriptive evidence does not support the myth.

An incorrect way to describe the findings would be:

> We statistically rejected the hypothesis.

This distinction is important because our project focuses on patterns in the data, not on formal statistical proof.

---

## Dataset Source

The dataset was obtained from Kaggle:

**International football results from 1872 to 2017**  
https://www.kaggle.com/datasets/martj42/international-football-results-from-1872-to-2017

The dataset contains historical information about international football matches. It includes match results, penalty shootouts, goalscorer information, and former team names.

The main CSV files used in this project are:

- `results.csv` — contains match-level results
- `shootouts.csv` — contains penalty shootout results
- `goalscorers.csv` — contains goalscorer-level data
- `former_names.csv` — contains historical team name information

---

## Main Entities in the Project

After reviewing the dataset, we identified the main entities needed for the database.

These entities are:

- Teams
- Tournaments
- Match locations
- Matches
- Penalty shootouts
- Goalscorers

These entities were then used to design the relational database schema.

---

## Database Schema Explanation

The database was created in Microsoft SQL Server.

The schema separates the data into dimension tables and fact tables. This makes the database easier to organize, query, and understand.

### Team Table

The `Team` table stores unique football team names.

Main columns:

- `TeamID`
- `TeamName`

This table helps avoid repeating team names many times in the match and goalscorer tables.

### Tournament Table

The `Tournament` table stores tournament names.

Main columns:

- `TournamentID`
- `TournamentName`

This allows each match to be connected to the tournament it belongs to.

### Location Table

The `Location` table stores information about where matches were played.

Main columns:

- `LocationID`
- `City`
- `Country`

This table helps separate location details from match records.

### Fact_match Table

The `Fact_match` table stores the main information about each football match.

Main columns:

- `MatchID`
- `MatchDate`
- `HomeTeamID`
- `AwayTeamID`
- `HomeScore`
- `AwayScore`
- `TournamentID`
- `LocationID`
- `IsNeutral`

This is one of the most important tables in the project because it contains the match results used for most of the analysis.

### Fact_shootout Table

The `Fact_shootout` table stores penalty shootout information.

Main columns:

- `ShootoutID`
- `MatchID`
- `WinnerTeamID`
- `FirstShooterTeamID`

This table is used to analyze whether the team shooting first has a strong advantage in penalty shootouts.

### Fact_goalscorer Table

The `Fact_goalscorer` table stores information about individual goal records.

Main columns:

- `GoalID`
- `MatchID`
- `ScoringTeamID`
- `ScorerName`
- `Minute`
- `IsOwnGoal`
- `IsPenalty`

This table allows us to analyze goal timing, penalties, own goals, and top scorers.

---

## ETL Pipeline Description

The project uses a Python ETL pipeline.

ETL stands for:

- Extract
- Transform
- Load

The pipeline is organized into separate Python files so that each part of the process is easier to manage.

### extract.py

The `extract.py` file is responsible for reading the raw CSV files into pandas DataFrames.

This step brings the raw data into Python so it can be cleaned and prepared.

### transform.py

The `transform.py` file cleans and prepares the data before it is loaded into the database.

The main cleaning steps include:

- Removing exact duplicate records
- Handling missing required values
- Converting date columns into datetime format
- Converting score and minute columns into numeric values
- Standardizing text fields
- Converting boolean fields into a consistent format
- Preparing clean datasets for loading

This step is important because raw datasets often contain missing values, inconsistent formatting, or data types that are not ready for database loading.

### load.py

The `load.py` file loads the cleaned data into Microsoft SQL Server.

The main loading steps include:

- Loading teams into the `Team` table
- Loading tournaments into the `Tournament` table
- Loading locations into the `Location` table
- Loading match records into the `Fact_match` table
- Loading shootout records into the `Fact_shootout` table
- Loading goalscorer records into the `Fact_goalscorer` table

This step connects the cleaned data with the relational database schema.

### main.py

The `main.py` file runs the full ETL process.

It runs the project in this order:

1. Extract the data
2. Transform the data
3. Load the data into SQL Server

This file acts as the main starting point for the pipeline.

---

## Required Software

Before running the project, the following software should be installed:

1. Python
2. Microsoft SQL Server
3. SQL Server Management Studio, also called SSMS
4. ODBC Driver 17 for SQL Server

These tools are needed to run the Python code, create the database, and connect Python to SQL Server.

---

## Required Python Packages

The required Python packages are listed in `requirements.txt`.

To install them, run:

```bash
pip install -r requirements.txt
```

The required packages are:

```text
pandas
sqlalchemy
pyodbc
```

These packages are used for data processing and database connection.

---

## Recommended Project Structure

The recommended project folder structure is:

```text
project/
│
├── data/
│   ├── results.csv
│   ├── shootouts.csv
│   ├── goalscorers.csv
│   └── former_names.csv
│
├── app/
│   ├── extract.py
│   ├── transform.py
│   ├── load.py
│   └── main.py
│
├── sql/
│   ├── schema.sql
│   └── queries.sql
│
├── README.md
└── requirements.txt
```

This structure keeps the project organized. The raw data is stored in the `data` folder, the Python code is stored in the `app` folder, and the SQL scripts are stored in the `sql` folder.

---

## Step 1: Create the Database

First, open SQL Server Management Studio and connect to your SQL Server instance.

Then run the following command:

```sql
CREATE DATABASE FootballProject;
GO
```

After creating the database, select it with:

```sql
USE FootballProject;
GO
```

This prepares SQL Server for the project tables.

---

## Step 2: Create the Database Schema

Open the following file:

```text
sql/schema.sql
```

Run the full script inside the `FootballProject` database.

This script creates the main tables, primary keys, and foreign key relationships.

---

## Step 3: Check the Python Database Connection

Open this file:

```text
app/main.py
```

Find the database connection string.

Example:

```python
db_connection_string = 'mssql+pyodbc://@DESKTOP-I9FM3CF\\SQLEXPRESS/FootballProject?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes'
```

If your SQL Server name is different, only change the server name part of the connection string.

Example for `localhost`:

```python
db_connection_string = 'mssql+pyodbc://@localhost/FootballProject?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes'
```

Example for `.\\SQLEXPRESS`:

```python
db_connection_string = 'mssql+pyodbc://@localhost\\SQLEXPRESS/FootballProject?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes'
```

This step is important because the Python pipeline must connect to the correct SQL Server instance.

---

## Step 4: Run the Python ETL Pipeline

Open PowerShell or Command Prompt.

Go to the `app` folder:

```bash
cd path\to\project\app
```

Then run:

```bash
python main.py
```

This command starts the ETL process. It reads the raw CSV files, cleans the data, and loads the cleaned data into SQL Server.

If the process runs successfully, the terminal should show:

```text
Data load complete!
```

---

## Step 5: Run the SQL Analysis Queries

After the data has been loaded, open this file:

```text
sql/queries.sql
```

Make sure the active database is:

```text
FootballProject
```

Then run the full script.

The script creates descriptive summary tables that are used for analysis and presentation.

The summary tables include:

- `Summary_00_DataQualityStatus`
- `Summary_01_DatabaseOverview`
- `Summary_02_MatchResults`
- `Summary_03_HomeAdvantageByDecade`
- `Summary_04_GoalsByDecade`
- `Summary_05_ScoreMarginDistribution`
- `Summary_06_GoalTiming`
- `Summary_07_GoalType`
- `Summary_08_ShootoutFirstShooter`
- `Summary_09_TeamPerformance`
- `Summary_10_TournamentScoring`
- `Summary_11_TopScorers`

These tables provide the final results for the project.

---

## Correct Running Order

The project should be run in this exact order:

```text
1. Create the FootballProject database
2. Run sql/schema.sql
3. Run app/main.py
4. Run sql/queries.sql
5. Use the summary tables for the final presentation
```

Following this order helps avoid database errors and missing table issues.

---

## SQL Analysis Summary

The SQL analysis focuses on descriptive questions about international football matches.

The analysis includes:

- General database overview
- Match result distribution
- Home advantage analysis
- Goal trends by decade
- Score margin distribution
- Goal timing analysis
- Penalty and own-goal summaries
- Penalty shootout first-shooter analysis
- Team performance summaries
- Tournament scoring summaries
- Top scorer summaries

The SQL queries use common SQL techniques, including:

- `JOIN`
- `GROUP BY`
- `ORDER BY`
- `WHERE`
- Aggregate functions
- Window functions such as `RANK()` and `LAG()`

These queries help turn the cleaned database into meaningful summary results.

---

## Main Descriptive Findings

The final summary tables support several descriptive findings.

First, home advantage exists, but home teams do not always win. This means the data shows some benefit for home teams, but the myth that the home team always wins is too strong.

Second, football is not simply becoming goalless or boring. The goal trends do not support the idea that football has clearly lost its scoring excitement.

Third, big wins do happen, but most matches are closer games. This means large score differences exist, but they are not the normal result.

Fourth, goals are not concentrated only in the final minutes. Goals can happen throughout the match, so the idea that most goals only happen near the end is not supported by the descriptive results.

Fifth, penalties and own goals are only a minority of all goal records. They are important moments in football, but they do not represent most goals.

Sixth, shooting first in a penalty shootout may matter in some cases, but it is not an absolute rule. The first-shooter advantage does not decide every shootout.

Finally, team-level summaries show that historical performance differs between teams. Some teams have stronger records than others, but this depends on the period, tournament, and number of matches played.

---

## Troubleshooting

### Cannot Open Database `FootballProject`

This usually means that the database was not created, or the Python connection string points to the wrong SQL Server instance.

To fix this, check the SQL Server name in SSMS and update the connection string in `main.py`.

### ODBC Driver Error

If there is an ODBC driver error, install ODBC Driver 17 for SQL Server.

After installing it, run the pipeline again.

### Tables Already Contain Data

If the ETL process was already run before, running it again may create duplicate rows in the fact tables, depending on the loader logic.

For a clean run, recreate the database or clear the tables before running the pipeline again.

---

## Final Note

This project was created as a university-level data ingestion and analytics pipeline.

The goal is not to prove or disprove football myths using formal statistics. Instead, the goal is to use a clean relational database and SQL summary queries to describe what the historical football data shows.

The results should therefore be presented as descriptive evidence, not as formal statistical proof.
