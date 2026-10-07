from pathlib import Path

import pandas as pd


DATA_DIR = Path("/Users/tomcraig/dev/mcz_notebooks_and_queries/WIN-2207/precompute_output_example_files")


csv_files = sorted(DATA_DIR.glob("*-domain_merged.csv"))

if not csv_files:
    raise FileNotFoundError(f"No matching CSV files found in {DATA_DIR}")


combined_df = pd.concat(
    [pd.read_csv(csv_file, low_memory=False).assign(source_file=csv_file.name) for csv_file in csv_files],
    ignore_index=True,
)

print(f"Loaded {len(csv_files)} files into one DataFrame")
print(f"Combined shape: {combined_df.shape}")
print(combined_df.head())
