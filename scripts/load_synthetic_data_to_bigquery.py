
import os
from pathlib import Path

from dotenv import load_dotenv
from google.cloud import bigquery


# Project configuration
PROJECT_ROOT = Path(__file__).resolve().parents[1]
load_dotenv(PROJECT_ROOT / ".env")

PROJECT_ID = os.getenv("GCP_PROJECT_ID")
DATASET_ID = os.getenv("BIGQUERY_DATASET")

if not PROJECT_ID or not DATASET_ID:
    raise ValueError("Missing BigQuery configuration in .env")

client = bigquery.Client(project=PROJECT_ID)

DATA_DIR = PROJECT_ROOT / "data" / "synthetic"


# Explicit schemas prevent incorrect type inference.
tables = {
    "crm_customers": {
        "file": DATA_DIR / "crm_customers.csv",
        "schema": [
            bigquery.SchemaField("customer_id", "STRING"),
            bigquery.SchemaField("first_name", "STRING"),
            bigquery.SchemaField("last_name", "STRING"),
            bigquery.SchemaField("email", "STRING"),
            bigquery.SchemaField("signup_date", "DATE"),
            bigquery.SchemaField("country", "STRING"),
            bigquery.SchemaField("customer_tier", "STRING"),
            bigquery.SchemaField("marketing_opt_in", "BOOL"),
        ],
    },
    "identity_links": {
        "file": DATA_DIR / "identity_links.csv",
        "schema": [
            bigquery.SchemaField("customer_id", "STRING"),
            bigquery.SchemaField("user_pseudo_id", "STRING"),
            bigquery.SchemaField("link_method", "STRING"),
            bigquery.SchemaField("is_simulated", "BOOL"),
        ],
    },
}


for table_name, config in tables.items():

    file_path = config["file"]

    if not file_path.exists():
        raise FileNotFoundError(f"File not found: {file_path}")

    table_id = f"{PROJECT_ID}.{DATASET_ID}.{table_name}"

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        schema=config["schema"],
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
    )

    print(f"\nLoading {table_name}...")

    with open(file_path, "rb") as csv_file:
        load_job = client.load_table_from_file(
            csv_file,
            table_id,
            job_config=job_config,
        )

    load_job.result()

    table = client.get_table(table_id)

    print(f"Successfully loaded: {table_id}")
    print(f"Rows loaded: {table.num_rows}")

print("\nAll synthetic datasets loaded into BigQuery.")
