# HR Workforce Analytics: SQL + Tableau

An end-to-end people-analytics project: cleaning a deliberately messy 7-table HR dataset in PostgreSQL, defining business questions, building a KPI view layer in SQL, and presenting the results in a three-page Tableau dashboard.

**Tools:** PostgreSQL (Supabase) · SQL · Tableau Desktop

---

## 1. Business problem

An HR leadership team wants to understand where it loses people, whether pay and performance processes look fair, and which recruiting channels deliver the best return. This project answers three groups of questions:

| Theme | Questions |
|---|---|
| **Workforce & attrition** | Which departments lose the most people? Are exits voluntary or involuntary? Does engagement explain who leaves? |
| **Compensation & performance** | Is there a gender pay gap? Do performance ratings and promotion rates differ by team? |
| **Recruiting** | Which sourcing channels convert best, fill roles fastest, and cost least per hire? |

33 business questions were defined (`BQ01`–`BQ33`) across headcount, attrition, compensation, performance, engagement, recruiting funnel and recruiting spend. One was dropped after investigation (see [Limitations](#6-limitations-and-assumptions)).

---

## 2. Data

Synthetic HR data in 7 tables, delivered as messy CSV files:

| Table | Grain | Notes |
|---|---|---|
| `employees` | one row per employee | department, job title, gender, age, location, employment type, hire date, manager |
| `compensation` | one row per employee | base salary (EUR), bonus target % |
| `performance_reviews` | one row per employee per review | rating, promotion flag |
| `attrition_events` | one row per leaver | termination date, voluntary/involuntary, reason, exit survey score |
| `engagement_surveys` | one row per employee per survey | engagement and satisfaction scores |
| `recruiting_funnel` | one row per candidate | source, department, final stage, days to fill |
| `recruiting_spend` | one row per source per month | spend in EUR |

---

## 3. Data cleaning

The raw tables were never modified. Each table was copied to a `_copy` working table, cleaned there, and exposed through a `_clean` view that downstream analysis reads from.

| Issue | How it was handled |
|---|---|
| Fake NULLs (`N/A`, `NULL`, `None`, `n/a`, `Unknown`, `--`) | Converted to real `NULL` |
| Inconsistent casing and spacing | `INITCAP(TRIM())`, then manual fixes for acronyms (e.g. `HR`) |
| Near-duplicate categories | Merged: `Job Board`/`Jobboard`, `Linked In`/`Linkedin`, `Contract`/`Contractor`, `Nb`/`Non-Binary`. `Contract` vs `Contractor` was merged only after comparing salary and bonus statistics for both groups and finding no meaningful difference |
| Four mixed date formats (`YYYY-MM-DD`, `MM/DD/YYYY`, `DD-MM-YYYY`, `Month DD, YYYY`) | Regex-driven `CASE` + `TO_DATE`, converted to `DATE` |
| Month-only dates (`YYYY-MM`) mixed with full dates | Normalised to the first day of the month |
| Currency stored as text (`€`, `EUR`, thousand separators) | Stripped and cast to `NUMERIC` |
| Impossible values (age 999 or negative, negative salary/spend/days-to-fill, engagement score 15 on a 1–10 scale) | Set to `NULL`. Rows were never deleted and values never imputed |
| Percentages stored as whole numbers | `bonus_target_pct` converted to a fraction (5 → 0.05) |
| Exact duplicate rows | Removed using the correct key per table: `employee_id` for one-row-per-person tables, `employee_id + date` for history tables, `candidate_id` for the funnel |
| Structural NULLs (e.g. `termination_date` for active staff, `days_to_fill` for non-hired candidates) | Kept. Confirmed by cross-tabulation that they are expected, not defects |

**Rule applied throughout:** delete a row only when an essential identifying field is missing; otherwise keep it with a `NULL`.

---

## 4. KPI layer

Six SQL views sit on top of the `_clean` views and feed Tableau directly:

| View | Purpose |
|---|---|
| `kpi_attrition_by_department` | headcount, terminations, attrition rate, voluntary vs involuntary |
| `kpi_engagement_vs_attrition` | average engagement/satisfaction next to attrition rate by department |
| `kpi_compensation_by_dept_gender` | average salary, bonus target and headcount by department and gender |
| `kpi_performance_by_department` | average rating, promotions and promotion rate by department |
| `kpi_recruiting_by_source` | candidates, hires, hire rate and average days to fill by source |
| `kpi_cost_per_hire_by_source` | total spend ÷ hires by source |

**Metric definitions**
- *Attrition rate* = terminations ÷ all employees in the employees table (not average headcount).
- *Promotion rate* = promotions ÷ total reviews.
- *Hire rate* = hires ÷ candidates for the source.
- *Cost per hire* = total recruiting spend for the source over all months ÷ hires from that source.

---

## 5. Dashboards and key findings

### Page 1: Workforce & Attrition
<p align="center">
  <img src="https://github.com/tilemaxoschatz-maker/hr_workforce_analytics/blob/main/dashboard_review/Screenshot%202026-10-21%20092555.png">
</p>

- **Sales (~30%) and Customer Success (~29%)** lose roughly 3 in 10 employees, 2.5 to 5 times the rate of stable teams such as Legal (~9%) and Finance (~6%).
- Of 147 recorded exits (employees with a known department), **102 (~69%) were voluntary**. Sales and Customer Success account for 83 exits, **over half of the total**.
- **Engagement is flat across departments** (average 6.1 to 6.6), so at department level it does not explain who leaves.

### Page 2: Compensation & Performance
<p align="center">
  <img src="https://github.com/tilemaxoschatz-maker/hr_workforce_analytics/blob/main/dashboard_review/Screenshot%202026-10-21%20092524.png">
</p>

- **No consistent gender pay gap**: in most departments the Female/Male difference in average salary is within about 1 to 3K in either direction.
- **Product is the exception**: men average ~93K vs ~84K for women (about 10% higher).
- **Performance ratings are flat** across teams (~2.8 to 3.0), but **promotion rates range from 2.5% (Finance) to 7.4% (Data & Analytics, Product)**.

### Page 3: Recruiting
<p align="center">
  <img src="https://github.com/tilemaxoschatz-maker/hr_workforce_analytics/blob/main/dashboard_review/Screenshot%202026-10-21%20093642.png">
</p>

- **Referral** has the best hire rate (21.5% vs 13.9% to 15.6% for other sources) and the lowest cost per hire (~€2.3K).
- Referral produced the **same number of hires as LinkedIn (53) from about 35% fewer candidates** (246 vs 380).
- **Recruiter Outreach costs ~€11K per hire**, almost 5 times Referral, without a better hire rate.
- Average days to fill ranges only from ~39 (LinkedIn) to ~47 (Career Site), a small spread.

---

## 6. Limitations and assumptions

- **No salary history.** `compensation` holds one record per employee, so the planned question on salary growth over time (BQ19) cannot be answered and was dropped.
- **Pay gap is a raw comparison.** It compares average base salary of Male and Female employees by department and is not adjusted for job level, tenure or seniority. Non-Binary and unspecified-gender groups were excluded from the comparison because the groups are too small for reliable averages.
- **Employees with a missing department** are excluded from department-level charts.
- **Small samples.** Several department/gender cells and recruiting sources rest on few records (e.g. 14 hires via Recruiter Outreach, 76 reviews in HR), so differences of a few points can reflect a handful of people. Findings are indicative.
- **Engagement vs attrition** was examined at department level only (10 data points). A per-employee comparison (last survey of leavers vs stayers) is a natural next step.
- **Dataset is synthetic.** Results illustrate the method and should not be read as real-world benchmarks.

---

## 7. Repository structure

```
hr-workforce-analytics/
├── README.md
├── data/raw/                     # original messy CSV files
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_cleaning.sql           # _copy tables and _clean views
│   ├── 03_business_questions.sql # BQ01–BQ33
│   └── 04_kpi_views.sql
├── tableau/
│   └── hr_workforce_analytics.twbx
└── images/                       # dashboard screenshots
```

## 8. How to reproduce

1. Create a PostgreSQL database (this project used a free Supabase project) and run `sql/01_create_tables.sql`.
2. Import the CSV files from `data/raw/` into the matching tables.
3. Run `sql/02_cleaning.sql` to build the `_copy` tables and `_clean` views.
4. Run `sql/04_kpi_views.sql` to create the six KPI views. Run `sql/03_business_questions.sql` to explore the underlying queries.
5. Export each KPI view to CSV (or connect directly) and open `tableau/hr_workforce_analytics.twbx`.
