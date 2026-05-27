import pandas as pd
from sqlalchemy import create_engine, text  

def load_data(cleaned_data, db_connection_string):
    print("Loading data into MS SQL Server...")
    engine = create_engine(db_connection_string)
    
    df_res = cleaned_data['results']
    df_shoot = cleaned_data['shootouts']
    df_goals = cleaned_data['goalscorers']

    with engine.begin() as conn:
        # 1. Loading(Team, Tournament, Location)
        all_teams = pd.concat([df_res['home_team'],df_res['away_team'], df_shoot['winner'], df_goals['team']]).dropna().unique()
        existing_teams = set(pd.read_sql("SELECT TeamName FROM Team", conn)['TeamName'].str.lower())
        new_teams = [t for t in all_teams if str(t).lower() not in existing_teams]
        if new_teams:
            pd.DataFrame({'TeamName': new_teams}).to_sql('Team', conn, if_exists='append', index=False)
        team_dict = {str(r['TeamName']).lower(): r['TeamID'] for _, r in pd.read_sql("SELECT TeamID, TeamName FROM Team", conn).iterrows()}

        all_tournaments = df_res['tournament'].dropna().unique()
        existing_tournaments = set(pd.read_sql("SELECT TournamentName FROM Tournament", conn)['TournamentName'].str.lower())
        new_tournaments = [t for t in all_tournaments if str(t).lower() not in existing_tournaments]
        if new_tournaments:
            pd.DataFrame({'TournamentName': new_tournaments}).to_sql('Tournament', conn, if_exists='append', index=False)
        tourn_dict = {str(r['TournamentName']).lower(): r['TournamentID'] for _, r in pd.read_sql("SELECT TournamentID, TournamentName FROM Tournament", conn).iterrows()}

        locs = df_res[['city', 'country']].drop_duplicates().rename(columns={'city': 'City', 'country': 'Country'})
        existing_locs = set(zip(pd.read_sql("SELECT City FROM Location", conn)['City'].str.lower(), pd.read_sql("SELECT Country FROM Location", conn)['Country'].str.lower()))
        new_locs = []
        for _, r in locs.iterrows():
            loc_tup = (str(r['City']).lower(), str(r['Country']).lower())
            if loc_tup not in existing_locs:
                new_locs.append({'City': r['City'], 'Country': r['Country']})
                existing_locs.add(loc_tup)
        if new_locs:
            pd.DataFrame(new_locs).to_sql('Location', conn, if_exists='append', index=False)
        loc_dict = {(str(r.City).lower(), str(r.Country).lower()): r.LocationID for _, r in pd.read_sql("SELECT LocationID, City, Country FROM Location", conn).iterrows()}

        # 2. Load FACT_MATCH
        # 2. Load FACT_MATCH
        print("Preparing Fact_match...")
        fact_match_df = pd.DataFrame({
            'MatchDate': df_res['date'],
            'HomeTeamID': df_res['home_team'].str.lower().map(team_dict),
            'AwayTeamID': df_res['away_team'].str.lower().map(team_dict),
            'HomeScore': df_res['home_score'],
            'AwayScore': df_res['away_score'],
            'TournamentID': df_res['tournament'].str.lower().map(tourn_dict),
            'LocationID': df_res.apply(lambda x: loc_dict.get((str(x['city']).lower(), str(x['country']).lower())), axis=1),
            'IsNeutral': df_res['neutral']
        }).dropna()
        
        # --- ԱՎԵԼԱՑՎԱԾ ՏՈՂ: Հեռացնում ենք նույն օրը նույն թիմերի միջև գրանցված կրկնակի խաղերը ---
        fact_match_df = fact_match_df.drop_duplicates(subset=['MatchDate', 'HomeTeamID', 'AwayTeamID'])
        
        # Խուսափում ենք կրկնօրինակ խաղերից
        fact_match_df.to_sql('#TempMatches', conn, if_exists='replace', index=False)
        
        conn.execute(text("""
            INSERT INTO Fact_match (MatchDate, HomeTeamID, AwayTeamID, HomeScore, AwayScore, TournamentID, LocationID, IsNeutral)
            SELECT t.* FROM #TempMatches t
            LEFT JOIN Fact_match f ON t.MatchDate = f.MatchDate AND t.HomeTeamID = f.HomeTeamID AND t.AwayTeamID = f.AwayTeamID
            WHERE f.MatchID IS NULL
        """))

        # Վերցնում ենք MatchID-ները մյուս աղյուսակների համար
        matches = pd.read_sql("SELECT MatchID, MatchDate, HomeTeamID, AwayTeamID FROM Fact_match", conn)
        match_dict = {(r.MatchDate.strftime('%Y-%m-%d'), r.HomeTeamID, r.AwayTeamID): r.MatchID for _, r in matches.iterrows()}

        # 3. Load FACT_SHOOTOUT
        print("Preparing Fact_shootout...")
        df_shoot['MatchID'] = df_shoot.apply(lambda x: match_dict.get((x['date'].strftime('%Y-%m-%d'), team_dict.get(str(x['home_team']).lower()), team_dict.get(str(x['away_team']).lower()))), axis=1)
        shoot_df = pd.DataFrame({
            'MatchID': df_shoot['MatchID'],
            'WinnerTeamID': df_shoot['winner'].str.lower().map(team_dict),
            'FirstShooterTeamID': df_shoot['first_shooter'].str.lower().map(team_dict)
        }).dropna(subset=['MatchID', 'WinnerTeamID']) # First shooter կարող է NULL լինել
        shoot_df.to_sql('Fact_shootout', conn, if_exists='append', index=False)

        # 4. Load FACT_GOALSCORER
        print("Preparing Fact_goalscorer...")
        df_goals['MatchID'] = df_goals.apply(lambda x: match_dict.get((x['date'].strftime('%Y-%m-%d'), team_dict.get(str(x['home_team']).lower()), team_dict.get(str(x['away_team']).lower()))), axis=1)
        goal_df = pd.DataFrame({
            'MatchID': df_goals['MatchID'],
            'ScoringTeamID': df_goals['team'].str.lower().map(team_dict),
            'ScorerName': df_goals['scorer'],
            'Minute': df_goals['minute'],
            'IsOwnGoal': df_goals['own_goal'],
            'IsPenalty': df_goals['penalty']
        }).dropna(subset=['MatchID', 'ScoringTeamID'])
        goal_df.to_sql('Fact_goalscorer', conn, if_exists='append', index=False)

        print("Data load complete!")