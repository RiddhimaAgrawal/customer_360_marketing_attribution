# Customer 360 Analytics & Marketing Attribution

An end-to-end analytics engineering capstone that transforms Google Analytics 4 ecommerce event data and synthetic CRM data into customer-level insights, verified order metrics, RFM segments, historical customer value, multi-touch marketing attribution, and campaign performance reporting.

## Project Overview

The project combines:
- Public GA4 ecommerce event data from the BigQuery public dataset.
- Synthetic CRM customer records.
- Synthetic identity links between GA4 visitors and CRM customers.
- Simulated campaign expenditure for demonstrating ROI and CPA calculations.

The pipeline uses dbt and BigQuery to clean, validate, transform, and model the data into analytics-ready tables.

## Architecture

```text
GA4 Public Ecommerce Events       Synthetic CRM Data
             |                           |
             v                           v
       Staging Models              Staging Models
             |                           |
             +-------------+-------------+
                           |
                           v
                  Intermediate Models
                           |
          +----------------+----------------+
          |                |                |
          v                v                v
    Customer Activity   Verified Orders   Touchpoints
          |                |                |
          v                |                v
    Customer 360            |         Order Attribution
          |                |                |
       +--+--+             |                v
       |     |             |       Campaign Performance
       v     v             |
      RFM   Historical     |
           Customer Value |
       |     |             |
       +-----+-------------+
                           |
                           v
