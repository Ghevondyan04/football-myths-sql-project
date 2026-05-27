# Data Cleaning and Preprocessing Explanation

## Overview

Before loading the football data into SQL Server, the raw CSV files were cleaned and transformed using Python.

The main goal of the cleaning process was to make the data suitable for relational database storage and descriptive SQL analysis.

The project uses three main datasets:

- `results.csv` — match-level results
- `shootouts.csv` — penalty shootout results
- `goalscorers.csv` — goalscorer-level data

The file `former_names.csv` was reviewed as historical naming information, but former team names were not automatically remapped in order to avoid historical misclassification.

---

## Cleaning Steps

### 1. Duplicate Records

Exact duplicate records were removed from the datasets.

This helps avoid counting the same match, shootout, or goal more than once.

---

### 2. Missing Values

Rows with missing required values were removed.

Examples of required fields:

- match date
- home team
- away team
- home score
- away score
- shootout winner
- goalscorer name

Some missing values were kept when they were not required for the analysis. For example, missing first-shooter information in shootouts was kept because the shootout result itself was still valid.

---

### 3. Date Standardization

Date columns were converted into datetime format.

This allowed the project to analyze matches by year and decade.

---

### 4. Numeric Type Conversion

Score and minute columns were converted into numeric format.

Examples:

- `home_score`
- `away_score`
- `minute`

This allowed SQL queries to calculate means, standard deviations, score margins, and goal timing summaries.

---

### 5. Boolean Type Conversion

Boolean fields were converted into consistent true/false values.

Examples:

- `neutral`
- `own_goal`
- `penalty`

This allowed filtering and grouped analysis in SQL.

---

### 6. Text Standardization

Text fields such as team names, tournament names, cities, and countries were standardized to improve consistency.

This was useful when matching teams across different datasets.

---

### 7. Relationship Validation

The datasets were checked to make sure that records were logically connected.

Examples:

- Every shootout should link to a valid match.
- Every goalscorer record should link to a valid match.
- The scoring team should be either the home team or the away team.
- The shootout winner should be either the home team or the away team.

---

## Accepted Data Limitations

Some small data limitations were accepted because they do not meaningfully affect the descriptive results.

For example:

- One conflicting duplicate match was identified.
- Some shootouts did not have first-shooter information.
- Some historical team names were kept as originally recorded.

These decisions were made to avoid introducing arbitrary corrections into the dataset.

---

## Final Cleaning Conclusion

After cleaning and validation, the data was considered appropriate for the purpose of this university project.

The cleaned data supports descriptive SQL analysis, including:

- match summaries
- home advantage analysis
- goal trends by decade
- score margin analysis
- goal timing analysis
- shootout summaries
- team performance summaries
