# Ahamove A2 — MySQL + Flask

Private GitHub is the **single source of truth** for executable code (`/sql`, `/app`, `/tests`) and presentation outlines (`/docs`). Every teammate runs MySQL locally on `localhost:3306` — do **not** host a shared free-tier cloud database for the demo.

## Stack (locked)

| Layer | Choice |
|---|---|
| DBMS | MySQL 8.0+ (`ahamove_a2` on `localhost:3306`) |
| App | Python 3 + Flask + Jinja2 + Bootstrap 5 |
| §2.1 focus table | `` `ORDER` `` |

## Quick start

```bash
# 1. Python
python3 -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env              # then edit MYSQL_PASSWORD

# 2. MySQL — recreate DB and load scripts (from A2/ root)
mysql -u root -p < sql/reset_demo.sql
mysql -u root -p ahamove_a2 < sql/01_schema.sql
mysql -u root -p ahamove_a2 < sql/02_seed.sql
mysql -u root -p ahamove_a2 < sql/03_programmability.sql

# Or one shot (prompts for password several times):
#   chmod +x sql/reset_demo.sh && ./sql/reset_demo.sh

# 3. Flask
cd app && python run.py
```

Open http://127.0.0.1:5000

Do **not** pipe a file that contains `SOURCE …` into `mysql < file.sql` — `SOURCE` is a client command and will raise error 1064.

### Demo reset

If a live demo mutates rows, re-run the four MySQL commands above (or `./sql/reset_demo.sh`).

## Repository layout

```text
sql/     Numbered, runnable DB scripts (+ reset_demo.sh)
app/     Flask web app (§3.1 / §3.2 / §3.3)
tests/   Per-object SQL harnesses for Section 2
docs/    Live demo script + oral defense cheat sheet (plain text)
```

## Feature-branch model

Keep `main` locked to code that runs end-to-end. After Phase 1 schema freeze, work on these persistent branches:

| Branch | Track | Owner | Primary ownership |
|---|---|---|---|
| `track-a-order-crud` | A | TBD | §2.1 CRUD procs + §3.1 UI + integration |
| `track-b-wallet-triggers` | B | TBD | §2.2.2 derived fee/balance triggers |
| `track-c-eligibility-fleet` | C | TBD | §2.2.1 C8 trigger + `fn_EvaluateFleetCompliance` |
| `track-d-search-ui` | D | TBD | `sp_Order_SearchDetailed` + §3.2 UI |
| `track-e-analytics-fn` | E | TBD | KPI proc + driver settlement fn + §3.3 UI |

Open a Pull Request into `main` only when your SQL object runs cleanly and includes its `tests/` harness.

See [CONTRIBUTING.md](CONTRIBUTING.md) for seed ID ranges, `SIGNAL` error style, and PR rules.

## Presentation docs (in git)

Keep rehearsal notes versioned here (owners fill blanks when roles are assigned):

1. [docs/live_demo_script.txt](docs/live_demo_script.txt) — who speaks, which UI control, which SQL object, expected output/error.
2. [docs/oral_defense_cheat_sheet.txt](docs/oral_defense_cheat_sheet.txt) — per-track business rule, DML, why not a plain DDL `CHECK`.

## SQL load order

1. `sql/00_schema_skeleton.sql` — frozen contract notes (reference)
2. `sql/01_schema.sql` — full DDL (23 tables) — **Phase 1 freeze**
3. `sql/02_seed.sql` — ≥5 rows per table (track-owned TODOs)
4. `sql/03_programmability.sql` — procedures, triggers, functions
5. `sql/reset_demo.sql` + `sql/reset_demo.sh` — rebuild for presentation day
