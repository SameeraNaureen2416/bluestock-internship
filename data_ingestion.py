import pandas as pd
import numpy as np
import os
import warnings
warnings.filterwarnings("ignore")

RAW_PATH = "data/raw/"

# Only load the 10 numbered assignment datasets (skip the nav_ files and the PDF)
csv_files = sorted([f for f in os.listdir(RAW_PATH) 
                     if f.endswith(".csv") and f[0:2].isdigit()])

print(f"Found {len(csv_files)} CSV files\n")

dataframes = {}
for file in csv_files:
    print(f"Loading: {file}")
    df = pd.read_csv(RAW_PATH + file)
    dataframes[file] = df
    print(f"  Shape: {df.shape}")
    print(f"  Dtypes:\n{df.dtypes.to_string()}")
    print(f"  Head:\n{df.head().to_string()}")
    missing = df.isnull().sum()
    print(f"  Missing values:\n{missing[missing>0].to_string() if missing.sum()>0 else '  None'}")
    print(f"  Duplicate rows: {df.duplicated().sum()}")
    print("=" * 70)

# --- Fund Master Exploration ---
fund_master = dataframes.get("01_fund_master.csv")
if fund_master is not None:
    print("\nFUND MASTER EXPLORATION")
    print(f"Fund Houses      : {fund_master['fund_house'].unique()}")
    print(f"Categories       : {fund_master['category'].unique()}")
    print(f"Sub-Categories   : {fund_master['sub_category'].unique()}")
    print(f"Risk Categories  : {fund_master['risk_category'].unique()}")
    print(f"Sample AMFI codes: {fund_master['amfi_code'].head(5).tolist()}")

# --- AMFI Code Validation ---
nav_history = dataframes.get("02_nav_history.csv")
if fund_master is not None and nav_history is not None:
    fund_codes = set(fund_master["amfi_code"].unique())
    nav_codes = set(nav_history["amfi_code"].unique())
    matching = fund_codes & nav_codes
    missing_codes = fund_codes - nav_codes

    print(f"\nAMFI CODE VALIDATION")
    print(f"Fund Master codes : {len(fund_codes)}")
    print(f"NAV History codes : {len(nav_codes)}")
    print(f"Matching codes    : {len(matching)}")
    print(f"Missing codes     : {len(missing_codes)}")
    print(f"Match Rate        : {len(matching)/len(fund_codes)*100:.1f}%")

    summary = pd.DataFrame({
        "Metric": ["Fund Master Records", "NAV History Records", "Matching Codes", "Missing Codes", "Match Rate"],
        "Value": [len(fund_master), len(nav_history), len(matching), len(missing_codes), f"{len(matching)/len(fund_codes)*100:.1f}%"]
    })
    os.makedirs("reports", exist_ok=True)
    summary.to_csv("reports/data_quality_summary.csv", index=False)
    print("\nData quality summary saved to reports/data_quality_summary.csv")

print("\nDay 1 Data Ingestion Complete!")