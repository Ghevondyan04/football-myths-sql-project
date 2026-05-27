import pandas as pd
from extract import extract_data
from transform import transform_data
from load import load_data

def main():
    db_connection_string = 'mssql+pyodbc://@DESKTOP-I9FM3CF\\SQLEXPRESS/FootballProject?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes'    
    file_paths = {
        'results': '../data/results.csv',
        'shootouts': '../data/shootouts.csv',
        'goalscorers': '../data/goalscorers.csv'
    }
    
    raw_data = extract_data(file_paths)
    
    if raw_data:
        cleaned_data = transform_data(raw_data)
        load_data(cleaned_data, db_connection_string)

if __name__ == "__main__":
    main()