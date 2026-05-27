import pandas as pd
import unicodedata

def clean_text(text):
    if pd.isna(text):
        return text
    text = str(text)
    # Here we normalize the text to remove accents and special characters
    text = unicodedata.normalize('NFKD', text).encode('ASCII', 'ignore').decode('utf-8')
    return text.strip().title()

def transform_data(raw_data):
    # Clean and transform all datasets
    print("Starting data transformation...")
    cleaned_data = {}

    # 1. Transform results.csv
    df_res = raw_data['results'].drop_duplicates().dropna(subset=['date', 'home_team', 'away_team', 'home_score', 'away_score']).copy()
    for col in ['home_team', 'away_team', 'tournament', 'city', 'country']:
        df_res[col] = df_res[col].apply(clean_text)
    df_res['date'] = pd.to_datetime(df_res['date'])
    df_res['home_score'] = df_res['home_score'].astype(int)
    df_res['away_score'] = df_res['away_score'].astype(int)
    df_res['neutral'] = df_res['neutral'].astype(bool)
    cleaned_data['results'] = df_res

    # 2. Transform shootouts.csv
    df_shoot = raw_data['shootouts'].drop_duplicates().dropna(subset=['date', 'home_team', 'away_team', 'winner']).copy()
    for col in ['home_team', 'away_team', 'winner', 'first_shooter']:
        df_shoot[col] = df_shoot[col].apply(clean_text)
    df_shoot['date'] = pd.to_datetime(df_shoot['date'])
    cleaned_data['shootouts'] = df_shoot

    # 3. Transform goalscorers.csv
    df_goals = raw_data['goalscorers'].drop_duplicates().dropna(subset=['date', 'home_team', 'away_team', 'team', 'scorer']).copy()
    for col in ['home_team', 'away_team', 'team', 'scorer']:
        df_goals[col] = df_goals[col].apply(clean_text)
    df_goals['date'] = pd.to_datetime(df_goals['date'])
    
    # Minute can be '90+3' we extract the numeric part and convert to int, treating non-numeric as NaN 
    df_goals['minute'] = pd.to_numeric(df_goals['minute'].astype(str).str.extract(r'(\d+)', expand=False), errors='coerce')
    df_goals['own_goal'] = df_goals['own_goal'].astype(bool)
    df_goals['penalty'] = df_goals['penalty'].astype(bool)
    cleaned_data['goalscorers'] = df_goals

    print("Data transformation complete:)")
    return cleaned_data