
import os
import random
from pathlib import Path
from datetime import date, timedelta

import pandas as pd
from dotenv import load_dotenv
from google.cloud import bigquery


# --------------------------------------------------
# 1. Project configuration
# --------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(PROJECT_ROOT / ".env")

PROJECT_ID = os.getenv("GCP_PROJECT_ID")
DATASET_ID = os.getenv("BIGQUERY_DATASET")

if not PROJECT_ID or not DATASET_ID:
    raise ValueError("Missing GCP_PROJECT_ID or BIGQUERY_DATASET in .env")

random.seed(42)

OUTPUT_DIR = PROJECT_ROOT / "data" / "synthetic"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


# --------------------------------------------------
# 2. Generate synthetic CRM customers
# --------------------------------------------------

NUM_CUSTOMERS = 3000

first_names = [
    "Aarav", "Riya", "Arjun", "Ananya", "Ishaan",
    "Meera", "Kabir", "Aditi", "Rahul", "Sneha",
    "Vivaan", "Diya", "Karan", "Priya", "Neha"
]

last_names = [
    "Sharma", "Agarwal", "Patel", "Verma", "Gupta",
    "Mehta", "Rao", "Singh", "Das", "Kapoor"
]

countries = [
    "India", "United States", "United Kingdom",
    "Canada", "Australia", "Germany", "Nepal"
]

tiers = ["Standard", "Silver", "Gold", "Platinum"]

start_date = date(2020, 10, 1)
end_date = date(2021, 1, 31)
date_range = (end_date - start_date).days

customers = []

for i in range(1, NUM_CUSTOMERS + 1):

    first_name = random.choice(first_names)
    last_name = random.choice(last_names)

    signup_date = start_date + timedelta(
        days=random.randint(0, date_range)
    )

    customers.append({
        "customer_id": f"CRM{i:06d}",
        "first_name": first_name,
        "last_name": last_name,
        "email": f"customer{i:06d}@example.com",
        "signup_date": signup_date.isoformat(),
        "country": random.choice(countries),
        "customer_tier": random.choice(tiers),
        "marketing_opt_in": random.choice([True, False])
    })

customers_df = pd.DataFrame(customers)


# --------------------------------------------------
# 3. Retrieve actual anonymous GA4 visitor IDs
# --------------------------------------------------

print("Connecting to BigQuery...")

client = bigquery.Client(project=PROJECT_ID)

query = f"""
SELECT DISTINCT user_pseudo_id
FROM `{PROJECT_ID}.{DATASET_ID}.int_ga4_sessions`
WHERE user_pseudo_id IS NOT NULL
ORDER BY FARM_FINGERPRINT(user_pseudo_id)
LIMIT 4500
"""

print("Retrieving anonymous GA4 visitor IDs...")

visitor_rows = client.query(query).result()

visitor_ids = [
    row.user_pseudo_id
    for row in visitor_rows
]

if len(visitor_ids) < NUM_CUSTOMERS:
    raise ValueError(
        f"Expected at least {NUM_CUSTOMERS} visitor IDs, "
        f"but retrieved only {len(visitor_ids)}."
    )


# --------------------------------------------------
# 4. Generate simulated identity links
# --------------------------------------------------

print("Generating simulated identity links...")

identity_links = []

# Give every synthetic customer one anonymous visitor ID.
for i, customer in enumerate(customers):

    identity_links.append({
        "customer_id": customer["customer_id"],
        "user_pseudo_id": visitor_ids[i],
        "link_method": "synthetic_assignment",
        "is_simulated": True
    })


# Assign additional visitor IDs to existing customers.
# This simulates customers visiting from multiple devices.

for visitor_id in visitor_ids[NUM_CUSTOMERS:]:

    customer = random.choice(customers)

    identity_links.append({
        "customer_id": customer["customer_id"],
        "user_pseudo_id": visitor_id,
        "link_method": "synthetic_assignment",
        "is_simulated": True
    })

identity_links_df = pd.DataFrame(identity_links)


# --------------------------------------------------
# 5. Save generated datasets
# --------------------------------------------------

customers_path = OUTPUT_DIR / "crm_customers.csv"
links_path = OUTPUT_DIR / "identity_links.csv"

customers_df.to_csv(customers_path, index=False)
identity_links_df.to_csv(links_path, index=False)

print("\nSynthetic CRM generation completed.")

print(f"CRM customers generated: {len(customers_df)}")
print(f"GA4 visitor IDs retrieved: {len(visitor_ids)}")
print(f"Identity links generated: {len(identity_links_df)}")

print(f"\nCustomer file: {customers_path}")
print(f"Identity links file: {links_path}")

print("\nIMPORTANT: Identity links are simulated, not actual customer matches.")
