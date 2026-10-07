from __future__ import annotations

import csv
from pathlib import Path
from typing import Iterable


INPUT_DIR = Path("/Users/tomcraig/dev/mcz_notebooks_and_queries/WIN-2207/int_connections")
WHITELIST_FILE = Path("/Users/tomcraig/dev/mcz_notebooks_and_queries/WIN-2207/first_250_npis.csv")
OUTPUT_DIR = Path("/Users/tomcraig/dev/mcz_notebooks_and_queries/WIN-2207/connections_for_first_250_npis")
FILE_BATCH_SIZE = 100


def batched(items: list[Path], batch_size: int) -> Iterable[list[Path]]:
    for start in range(0, len(items), batch_size):
        yield items[start : start + batch_size]


def load_whitelist(path: Path) -> list[str]:
    npis: list[str] = []

    with path.open(newline="") as handle:
        reader = csv.reader(handle)
        for row in reader:
            if not row:
                continue

            value = row[0].strip()
            if not value or value.lower() == "npi":
                continue

            npis.append(value)

    return npis


def main() -> None:
    source_files = sorted(INPUT_DIR.glob("*.csv"))
    if not source_files:
        raise FileNotFoundError(f"No CSV files found in {INPUT_DIR}")

    whitelist = load_whitelist(WHITELIST_FILE)
    if not whitelist:
        raise ValueError(f"No NPI values found in {WHITELIST_FILE}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    whitelist_set = set(whitelist)
    writers: dict[str, csv.writer] = {}
    output_handles: dict[str, object] = {}
    row_counts = {npi: 0 for npi in whitelist}
    header: list[str] | None = None

    try:
        for batch_number, file_batch in enumerate(batched(source_files, FILE_BATCH_SIZE), start=1):
            print(f"Processing batch {batch_number}: {len(file_batch)} file(s)")

            for csv_file in file_batch:
                print(f"  Reading {csv_file.name}")

                with csv_file.open(newline="") as input_handle:
                    reader = csv.reader(input_handle)
                    file_header = next(reader, None)
                    if file_header is None:
                        continue

                    if header is None:
                        header = file_header
                    elif file_header != header:
                        raise ValueError(f"Header mismatch in {csv_file}")

                    for row in reader:
                        if not row:
                            continue

                        npi = row[0].strip()
                        if npi not in whitelist_set:
                            continue

                        if npi not in writers:
                            output_path = OUTPUT_DIR / f"{npi}.csv"
                            output_handle = output_path.open("w", newline="")
                            writer = csv.writer(output_handle)
                            writer.writerow(header)
                            writers[npi] = writer
                            output_handles[npi] = output_handle

                        writers[npi].writerow(row)
                        row_counts[npi] += 1

        if header is None:
            raise ValueError("No headers found in the source CSV files")

        for npi in whitelist:
            if npi in writers:
                continue

            output_path = OUTPUT_DIR / f"{npi}.csv"
            with output_path.open("w", newline="") as output_handle:
                writer = csv.writer(output_handle)
                writer.writerow(header)

        matched_file_count = sum(1 for count in row_counts.values() if count > 0)
        print(f"Created {len(whitelist)} output file(s) in {OUTPUT_DIR}")
        print(f"{matched_file_count} NPI file(s) contain at least one matching row")
        print(f"{len(whitelist) - matched_file_count} NPI file(s) contain header only")
    finally:
        for handle in output_handles.values():
            handle.close()


if __name__ == "__main__":
    main()
