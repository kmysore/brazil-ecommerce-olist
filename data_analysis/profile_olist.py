"""Olist data profiling (pandas). Usage: python profile_olist.py /path/to/csv/folder"""

import pandas as pd
import glob, os, sys

folder = sys.argv[1] if len(sys.argv) > 1 else "."

for path in sorted(glob.glob(os.path.join(folder, "*.csv"))):
    name = os.path.basename(path)
    print("\n" + "=" * 70)
    print(name)
    print("=" * 70)

    df = pd.read_csv(path)

    print(f"Rows: {len(df):,}")
    print(f"Columns: {len(df.columns)}")

    for col in df.columns:
        nulls = df[col].isnull().sum()
        distinct = df[col].nunique()
        dtype = str(df[col].dtype)
        flag = "  <-- has nulls" if nulls > 0 else ""
        print(f"  {col:<35} {dtype:<10} nulls={nulls:<8} distinct={distinct}{flag}")