# GlucoCare-Commercial-Performance-Analytics

A pharmaceutical commercial analytics project: SQL diagnostics → Tableau dashboard.

## Business Story

PharmaX launched a diabetes drug, GlucoCare, competing against two rivals
(DiabetoShield, SugarBlock) across 10 Indian territories rolling up to 4 regions
(North / South / East / West), over a 12-month period (Jan–Dec 2024).

Market share is falling in some territories (especially South) while holding up
elsewhere (East). This project finds out why and recommends what to do about it.

## Key Patterns in the Data

- Competitor price pressure in 2 South territories from month 6 onward
- Sales call cutback in the same 2 territories from month 6 onward
- Some reps convert calls to prescriptions less efficiently than others
- High-potential doctors receiving very few rep calls
- Digital marketing spend outperforms TV spend on prescriptions generated
- Some doctors switch to a competitor mid-year

## Data

Cleaned dataset (7 CSVs) sourced from Kaggle, covering territories, doctors, sales
reps, rep activity, marketing spend, competitor pricing, and prescriptions.

## Repo Structure

```
glucocare-portfolio/
├── dataset/                                 # 7 CSV files    
├── image/
│   └── Pharma Analysis Screenshot.png       # Screenshot of dashboard
├── sql/
│   ├── 01_schema.sql                        # Table definitions
│   └── 02_business_queries.sql              # 10 business queries
└── tableau/
    └── README.md                            # Dashboard details
```

## Tech Stack

- SQL (basic dialect — SELECT, JOIN, GROUP BY, CASE WHEN, subqueries, aggregates)
- Tableau — "GlucoCare Commercial Performance" dashboard

## How to Reproduce

1. Load the CSVs from `dataset/` into a SQL database
2. Run `sql/01_schema.sql` to create tables
3. Run `sql/02_business_queries.sql` for the analysis
4. Open the Tableau dashboard — see `tableau/README.md`
