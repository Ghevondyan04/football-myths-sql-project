import pandas as pd

def extract_data(file_paths):
    # Loads raw data from multiple files
    print("Extracting data...")
    raw_data = {}
    try:
        for key, path in file_paths.items():
            df = pd.read_csv(path)
            raw_data[key] = df
            print(f"Successfully extracted {len(df)} rows from {key}.")
        return raw_data
    except Exception as e:
        print(f"Error extracting data: {e}")
        return None