# NYC Taxi + Weather Modern Data‑Warehouse Pipeline

> **Goal:** Build a production‑grade, end‑to‑end data pipeline that lands NYC Taxi trip records & NOAA hourly weather into an AWS‑based warehouse, transforms them with dbt, and serves a public Metabase dashboard showing *median pickup‑to‑drop travel‑time by zone vs. rain intensity*.

---

## ✨ Why this project matters
- **Job‑ready tech stack** — Python, SQL, Airflow, dbt, S3, Redshift Serverless, Metabase.
- **Business KPI focus** — answers a question ride‑hailing ops teams actually care about.
- **Production discipline** — IaC (Terraform), CI/CD (GitHub Actions), data‑quality tests, cost & performance benchmarks.

Recruiters complain that most “NYC Taxi” demos stop at a Jupyter notebook. This repo shows what a *junior Data Engineer* can do when they think like an engineer, not a student.

---

## 🛠️ Tech Stack
| Layer | Tool / Service |
|-------|----------------|
| Ingest Storage | **Amazon S3** (`s3://nyc-taxi-raw/`, `s3://nyc-weather-raw/`) |
| Orchestration | **Apache Airflow** (Docker Compose; MWAA optional) |
| Compute + Warehouse | **Amazon Redshift Serverless** (8 RPU) |
| Transform | **dbt Core** (incremental models, tests, docs) |
| BI / Demo | **Metabase** (public share link) |
| IaC & CI | **Terraform**, **GitHub Actions** |
| Monitoring | Airflow SLA e‑mails + Slack webhook |

---

## 📐 High‑Level Architecture (MVP)
```
           +---------------------+           +-----------------------+
           |  NYC TLC S3 bucket  |<-- Airflow|  DAG: taxi_ingest.py  |
           +---------------------+           +----------+------------+
                                                 |
 NOAA CDO API --> Lambda (weather_loader) --> S3 weather_raw
                                                 |
                         +-----------------------+--------------------+
                         |
             +-----------v------------+      dbt run/test   +---------------+
             |  Redshift Staging      |  ------------------> |  dbt Marts    |
             | stg_taxi, stg_weather  |                     |  fct_trips…   |
             +-----------+------------+                     +-------+-------+
                         |                                         |
                         |                              Metabase public dash
                     GitHub Actions CI                      (zone x rain KPI)
```
*See [`docs/architecture.png`](docs/architecture.png) for a nicer diagram.*

---

## 🚀 Quick Start
```bash
# 1. Clone & set up Python env
$ git clone https://github.com/<your-user>/nyc-taxi-pipeline.git
$ cd nyc-taxi-pipeline && make dev

# 2. Provision AWS infra (S3 + Redshift)
$ cd infra && terraform init && terraform apply

# 3. Launch local Airflow & run first load (Jan 2025)
$ make airflow-up
$ airflow dags trigger taxi_ingest --conf '{"year": 2025, "month": 1}'

# 4. Build dbt models & tests
$ cd dbt && dbt build

# 5. View KPI dashboard (Metabase)
#    -> http://localhost:3000/public/dashboard/<id>
```
*Detailed instructions live in [`docs/setup.md`](docs/setup.md).*

---

## 📊 Key Models & Metrics
| Model | Grain | Description |
|-------|-------|-------------|
| `fct_trips` | trip_id | Cleaned taxi trips with geo‑enriched pick‑up/drop‑off zones |
| `dim_weather_hr` | station_id + hour | Hourly precip/temp for NYC stations |
| `mart_zone_wait_weather` | zone_id + hour | Median travel‑time & precip bucket, feeds dashboard |

**Headline KPI:** *Median travel time increases by **X %** when rain > 2 mm/hr south of 34th St.* (placeholder until data lands).

---

## 🛣️ Roadmap
- [x] Scaffold repo, Terraform modules
- [ ] Airflow raw ingests (taxi & weather)
- [ ] Staging dbt models + tests
- [ ] Core marts + KPI model
- [ ] Metabase dashboard v1
- [ ] CI/CD pipeline & cost benchmarks
- [ ] Optional: TLC live minute‑feed via Kinesis
- [ ] Blog post & Loom walkthrough

---

## 🤝 Git Workflow
Follow this simple branch & commit convention to keep history readable and automate change‑log generation:

```text
Branches:
  feature/<short-topic> — new capability
  fix/<bug>             — bug‑fix
  chore/<misc>          — CI, docs, deps bump

Commits:
  <scope>: <imperative>   e.g., "airflow: add taxi_ingest DAG skeleton"
```

---

