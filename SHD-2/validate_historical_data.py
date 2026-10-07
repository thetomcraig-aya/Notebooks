"""
WFAI Historical Data Quality Validator
======================================
Validates a historical workload CSV for data quality only — no lookup-table
matching. Designed for new-unit onboarding where the file should stand on
its own merits.

Checks:
  - Schema (expected columns present)
  - Date range, span, and unique-date coverage
  - Hour range (0–23) and boundary-day truncation
  - Volume statistics (nulls, negatives, zeros, range)
  - Per-(Type, Unit) coverage: span, missing calendar days, missing hour-slots
  - Duplicate full rows
  - Duplicate keys: same (Type, Unit, VolDate, VolHour) with conflicting Volume

Usage:
    python script/validate_historical_data.py
    WFAI_CLIENT=Wellspan WFAI_HIST_FILTER=Historical python script/validate_historical_data.py
"""

import pandas as pd
import os
import sys
from datetime import datetime

# ─── Configuration ───────────────────────────────────────────────────────────

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CLIENT = os.environ.get("WFAI_CLIENT", "Wellspan")
HISTORICAL_DIR = "."
HIST_FILE_FILTER = os.environ.get("WFAI_HIST_FILTER", "Historical")

EXPECTED_COLUMNS = ["Type", "Facility", "Unit", "VolDate", "VolHour", "Volume"]

SEPARATOR = "=" * 80
SUBSEP = "-" * 80

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")


# ─── Helpers ─────────────────────────────────────────────────────────────────

def find_csv_files(directory):
    if not os.path.isdir(directory):
        return []
    return [
        os.path.join(directory, f)
        for f in os.listdir(directory)
        if f.lower().endswith(".csv")
    ]


def print_header(title):
    print(f"\n{SEPARATOR}")
    print(f"  {title}")
    print(SEPARATOR)


def print_subheader(title):
    print(f"\n{SUBSEP}")
    print(f"  {title}")
    print(SUBSEP)


# ─── Main ────────────────────────────────────────────────────────────────────

def main():
    print(SEPARATOR)
    print("  WFAI HISTORICAL DATA QUALITY REPORT")
    print(f"  Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(SEPARATOR)

    hist_files = find_csv_files(HISTORICAL_DIR)
    if not hist_files:
        print(f"\n[ERROR] No CSV files found in {HISTORICAL_DIR}")
        sys.exit(1)

    if HIST_FILE_FILTER:
        filtered = [
            p for p in hist_files
            if HIST_FILE_FILTER.lower() in os.path.basename(p).lower()
        ]
        if filtered:
            hist_files = filtered

    hist_path = hist_files[0]
    print(f"\n  File : {os.path.basename(hist_path)}")

    df = pd.read_csv(hist_path, sep=None, engine="python", encoding="utf-8-sig")
    issues = []

    # ── 1. Schema ────────────────────────────────────────────────────────────

    print_header("1. SCHEMA")

    print(f"\n  Total Rows    : {len(df):,}")
    print(f"  Total Columns : {len(df.columns)}")
    print(f"  Columns       : {', '.join(df.columns.tolist())}")

    missing_cols = [c for c in EXPECTED_COLUMNS if c not in df.columns]
    extra_cols = [c for c in df.columns if c not in EXPECTED_COLUMNS]
    if missing_cols:
        print(f"  [FLAG] Missing expected columns: {missing_cols}")
        issues.append(f"Missing columns: {missing_cols}")
    if extra_cols:
        print(f"  [INFO] Extra columns: {extra_cols}")
    if not missing_cols and not extra_cols:
        print(f"  [PASS] Schema matches expected columns.")

    # ── 2. Date / Hour Coverage ──────────────────────────────────────────────

    print_header("2. DATE & HOUR COVERAGE")

    df["_d"] = pd.to_datetime(df["VolDate"], format="mixed", errors="coerce")
    valid_dates = df["_d"].dropna()
    unparsed = df["VolDate"].notna().sum() - len(valid_dates)

    if not valid_dates.empty:
        mn = valid_dates.min()
        mx = valid_dates.max()
        span_days = (mx - mn).days + 1
        unique_dates = valid_dates.dt.date.nunique()
        expected = pd.date_range(mn.normalize(), mx.normalize(), freq="D")
        actual = pd.DatetimeIndex(valid_dates.dt.normalize().unique())
        global_missing = expected.difference(actual)

        print(f"\n  Date Range         : {mn.strftime('%m/%d/%Y')} → {mx.strftime('%m/%d/%Y')}")
        print(f"  Span (inclusive)   : {span_days:,} days ({span_days / 30:.1f} months)")
        print(f"  Unique Dates       : {unique_dates:,}")
        print(f"  Calendar Gap Days  : {len(global_missing):,}  (entire dataset)")
        if unparsed > 0:
            print(f"  [FLAG] Unparseable Dates: {unparsed:,}")
            issues.append(f"{unparsed:,} unparseable date values")

        # Boundary-day truncation
        first_hours = sorted(df.loc[df["_d"] == mn, "VolHour"].unique())
        last_hours = sorted(df.loc[df["_d"] == mx, "VolHour"].unique())
        print(f"\n  First day hours    : {len(first_hours)} ({min(first_hours)}–{max(first_hours)})")
        print(f"  Last day hours     : {len(last_hours)} ({min(last_hours)}–{max(last_hours)})")
        if len(first_hours) < 24:
            print(f"  [INFO] First day partial ({len(first_hours)}/24 hours).")
        if len(last_hours) < 24:
            print(f"  [INFO] Last day partial ({len(last_hours)}/24 hours) — likely generation-time cutoff.")

    if "VolHour" in df.columns:
        print(f"\n  Hour Range         : {int(df['VolHour'].min())}–{int(df['VolHour'].max())}")
        bad_hours = df[(df["VolHour"] < 0) | (df["VolHour"] > 23)].shape[0]
        status = "[PASS]" if bad_hours == 0 else "[FLAG]"
        print(f"  {status} Invalid Hours : {bad_hours:,}")
        if bad_hours > 0:
            issues.append(f"{bad_hours:,} rows with hours outside 0–23")

    # ── 3. Volume Statistics ─────────────────────────────────────────────────

    print_header("3. VOLUME STATISTICS")

    if "Volume" in df.columns:
        v = df["Volume"]
        nulls = v.isna().sum()
        neg = (v < 0).sum()
        zero = (v == 0).sum()
        print(f"\n  Min            : {v.min()}")
        print(f"  Max            : {v.max()}")
        print(f"  Mean           : {v.mean():.2f}")
        print(f"  Median         : {v.median():.1f}")
        print(f"  Null Count     : {nulls:,}")
        print(f"  Zero Count     : {zero:,}  ({zero / len(df) * 100:.1f}% of rows)")
        if neg > 0:
            print(f"  [FLAG] Negative Values: {neg:,}")
            issues.append(f"{neg:,} negative volume values")
        if nulls > 0:
            issues.append(f"{nulls:,} null Volume values")

    # ── 4. Type / Facility Breakdown ─────────────────────────────────────────

    print_header("4. CONTENT BREAKDOWN")

    if "Type" in df.columns:
        print(f"\n  Record Types:")
        for t, c in df["Type"].value_counts().items():
            print(f"    {t:<30}: {c:>12,} rows")

    if "Facility" in df.columns:
        print(f"\n  Facilities ({df['Facility'].nunique()}):")
        for f, c in df["Facility"].value_counts().items():
            print(f"    {f:<40}: {c:>10,} rows")

    if "Unit" in df.columns:
        print(f"\n  Unique Units : {df['Unit'].nunique():,}")

    # ── 5. Per-(Type, Unit) Coverage ─────────────────────────────────────────

    print_header("5. PER-(TYPE, UNIT) COVERAGE & GAPS")

    coverage_rows = []
    for (type_val, raw_unit), subset in df.groupby(["Type", "Unit"], sort=True):
        dates = subset["_d"].dropna()
        if dates.empty:
            coverage_rows.append((type_val, raw_unit, "N/A", "N/A", 0, 0, 0, len(subset), []))
            continue

        sub_mn = dates.min()
        sub_mx = dates.max()
        span = (sub_mx - sub_mn).days + 1

        sub_expected = pd.date_range(sub_mn.normalize(), sub_mx.normalize(), freq="D")
        sub_actual = pd.DatetimeIndex(dates.dt.normalize().unique())
        miss_days_idx = sub_expected.difference(sub_actual)
        miss_days = len(miss_days_idx)

        if "VolHour" in subset.columns:
            hours_per_date = (
                subset.dropna(subset=["_d"])
                      .groupby(subset["_d"].dt.normalize())["VolHour"]
                      .nunique()
            )
            miss_hours = int((24 - hours_per_date).clip(lower=0).sum())
        else:
            miss_hours = 0

        samples = [d.strftime("%m/%d/%Y") for d in miss_days_idx[:5]]
        coverage_rows.append(
            (type_val, raw_unit, sub_mn.strftime("%m/%d/%Y"),
             sub_mx.strftime("%m/%d/%Y"), span, miss_days, miss_hours,
             len(subset), samples)
        )

    print(f"\n  {'Type':<22} {'Unit':<55} {'Min':<12} {'Max':<12} {'Days':>5}  {'MissDay':>7}  {'MissHr':>7}  {'Rows':>9}")
    print(f"  {'─'*22} {'─'*55} {'─'*11} {'─'*11} {'─'*5}  {'─'*7}  {'─'*7}  {'─'*9}")
    for t, u, mn_s, mx_s, sp, md, mh, n, _ in sorted(coverage_rows):
        u_short = u[:55]
        print(f"  {t:<22} {u_short:<55} {mn_s:<12} {mx_s:<12} {sp:>5}  {md:>7,}  {mh:>7,}  {n:>9,}")

    gaps = [r for r in coverage_rows if r[5] > 0]
    if gaps:
        print_subheader("5a. UNITS WITH MISSING CALENDAR DAYS")
        print()
        for t, u, _, _, _, md, mh, _, samples in sorted(gaps, key=lambda x: -x[5]):
            print(f"    [{t}] {u}")
            print(f"        Missing days : {md:,}  |  Missing hour-slots: {mh:,}")
            if samples:
                print(f"        Examples     : {', '.join(samples)}")
        issues.append(f"{len(gaps)} (Type, Unit) combinations have missing calendar days")
    else:
        print_subheader("5a. UNITS WITH MISSING CALENDAR DAYS")
        print("\n    [PASS] No internal date gaps for any (Type, Unit) combination.")

    # ── 6. Duplicates & Key Integrity ────────────────────────────────────────

    print_header("6. DUPLICATES & KEY INTEGRITY")

    print(f"\n  Null Check (key columns):\n")
    for col in EXPECTED_COLUMNS:
        if col in df.columns:
            n = df[col].isna().sum()
            status = "[PASS]" if n == 0 else "[FLAG]"
            print(f"    {status} {col:<10}: {n:>10,} nulls")
            if n > 0:
                issues.append(f"{col} has {n:,} null values")

    print()
    full_dup = df.duplicated().sum()
    status = "[PASS]" if full_dup == 0 else "[FLAG]"
    print(f"    {status} Full-Row Duplicates : {full_dup:>10,}")
    if full_dup > 0:
        issues.append(f"{full_dup:,} full-row duplicates")

    key_cols = ["Type", "Unit", "VolDate", "VolHour"]
    if all(c in df.columns for c in key_cols):
        key_dup = df.duplicated(subset=key_cols).sum()
        status = "[PASS]" if key_dup == 0 else "[FLAG]"
        print(f"    {status} Duplicate Keys      : {key_dup:>10,}  (same Type+Unit+Date+Hour)")
        if key_dup > 0:
            offenders = (
                df[df.duplicated(subset=key_cols, keep=False)]
                .groupby("Unit").size().sort_values(ascending=False)
            )
            issues.append(
                f"{key_dup:,} rows share a (Type,Unit,Date,Hour) key with another row "
                f"— suggests sub-locations rolled up under one Unit string"
            )
            print(f"\n    Top affected units:")
            for unit, cnt in offenders.head(5).items():
                print(f"      {cnt:>8,} rows — {unit}")

    # ── 7. Summary ───────────────────────────────────────────────────────────

    print_header("7. SUMMARY")

    if issues:
        print(f"\n  Status: FLAG — {len(issues)} issue(s) require attention\n")
        for i, issue in enumerate(issues, 1):
            print(f"    {i}. {issue}")
    else:
        print(f"\n  Status: PASS — No data quality issues detected.")

    print(f"\n{SEPARATOR}\n  END OF REPORT\n{SEPARATOR}\n")

    if "_d" in df.columns:
        df.drop(columns=["_d"], inplace=True)


if __name__ == "__main__":
    main()
