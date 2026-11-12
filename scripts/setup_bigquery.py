import os
from pathlib import Path

from dotenv import load_dotenv
from google.cloud import bigquery


# Load environment variables from the project root
PROJECT_ROOT = Path(__file__).resolve().parents[1]
load_dotenv(PROJECT_ROOT / ".env")

PROJECT_ID = os.getenv("GCP_PROJECT_ID")
DATASET_ID = os.getenv("BIGQUERY_DATASET")
SOURCE_DATASET_ID = os.getenv("GA4_SOURCE_DATASET")

if not all([PROJECT_ID, DATASET_ID, SOURCE_DATASET_ID]):
    raise ValueError("Missing required configuration in .env")

# Connect to BigQuery
client = bigquery.Client(project=PROJECT_ID)

# Get the source dataset's location
source_dataset = client.get_dataset(SOURCE_DATASET_ID)
location = source_dataset.location

print(f"Source dataset location: {location}")

# Create our own destination dataset
destination_dataset = bigquery.Dataset(
    f"{PROJECT_ID}.{DATASET_ID}"
)
destination_dataset.location = location

client.create_dataset(destination_dataset, exists_ok=True)

print(f"Dataset ready: {PROJECT_ID}.{DATASET_ID}")
print("BigQuery project setup completed.")