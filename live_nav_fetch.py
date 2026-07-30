import requests
import pandas as pd
import os
import time
from datetime import datetime

RAW_PATH = "data/raw/"
os.makedirs(RAW_PATH, exist_ok=True)
BASE_URL = "https://api.mfapi.in/mf/"

SCHEMES = {
    "HDFC_Top100_Direct": 125497,
    "SBI_Bluechip":       119551,
    "ICICI_Bluechip":     120503,
    "Nippon_LargeCap":    118632,
    "Axis_Bluechip":      119092,
    "Kotak_Bluechip":     120841,
}

def fetch_nav(scheme_name, scheme_code):
    print(f"\nFetching: {scheme_name} (Code: {scheme_code})")
    url = f"{BASE_URL}{scheme_code}"
    try:
        response = requests.get(url, timeout=20)
        if response.status_code == 200:
            data = response.json()
            meta = data.get("meta", {})
            nav_data = data.get("data", [])
            print(f"  Fund Name  : {meta.get('scheme_name', 'N/A')}")
            print(f"  NAV Records: {len(nav_data)}")
            df = pd.DataFrame(nav_data)
            df["scheme_code"] = scheme_code
            df["scheme_name"] = meta.get("scheme_name", scheme_name)
            df["fund_house"] = meta.get("fund_house", "N/A")
            df["fetched_at"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            df["nav"] = pd.to_numeric(df["nav"], errors="coerce")
            filename = f"{RAW_PATH}nav_{scheme_name}.csv"
            df.to_csv(filename, index=False)
            print(f"  Saved to   : {filename}")
            return df
        else:
            print(f"  Failed! Status: {response.status_code}")
            return None
    except Exception as e:
        print(f"  Error: {e}")
        return None

all_dfs = []
for name, code in SCHEMES.items():
    df = fetch_nav(name, code)
    if df is not None:
        all_dfs.append(df)
    time.sleep(0.5)

if all_dfs:
    master = pd.concat(all_dfs, ignore_index=True)
    master.to_csv(f"{RAW_PATH}nav_all_schemes_combined.csv", index=False)
    print(f"\nDone! Total records: {len(master)}")