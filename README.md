
# Customer 360 Analytics & Marketing Attribution

An end-to-end analytics engineering capstone that transforms Google Analytics 4 ecommerce event data and synthetic CRM data into customer-level insights, verified order metrics, RFM segments, historical customer value, multi-touch marketing attribution, and campaign performance reporting.
## Interactive Tableau Dashboard

Explore the complete Customer 360 – Marketing Attribution project through the interactive Tableau Public workbook.

## Tableau Dashboards

**[View all three interactive dashboards on Tableau Public](https://public.tableau.com/app/profile/riddhima.agrawal/viz/Customer360MarketingAttributionAnalytics)**

The project includes three dashboards:

1. **Executive Overview:** Revenue trends, customer distribution and RFM segmentation.
2. **Marketing & Attribution:** Channel performance and comparison of First-Touch, Last-Touch, Linear and Time-Decay attribution.
3. **Campaign & Customer Insights:** Campaign revenue, illustrative ROAS/ROI and historical customer value.

The dashboards use the project's exported analytical datasets. Campaign spend is simulated, and campaign efficiency metrics are illustrative rather than actual business returns.


### Key Project Highlights

- 4,466 verified candidate orders after purchase-event deduplication.
- $308,830 in deduplicated order revenue.
- Four attribution models: First Touch, Last Touch, Linear, and Time Decay.
- Customer segmentation using RFM analysis.
- Customer 360 profiles integrating synthetic CRM and identity-link data.
- Campaign performance analysis using simulated marketing spend.

**Data Disclaimer:** CRM records, identity links, and campaign spend are synthetic. Campaign efficiency metrics are illustrative, and customer identity mapping has limited verified purchase coverage.

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
