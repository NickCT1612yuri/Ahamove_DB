# Contributing

## Branch & PR rules

1. Do **not** commit unfinished SQL or broken DDL straight to `main`.
2. Work on your persistent track branch (`track-a-…` … `track-e-…`).
3. Open a PR into `main` only when:
   - your Section 2 object(s) run without syntax errors on a clean `reset_demo.sql`;
   - the matching file under `tests/` includes at least one happy-path and one failure-path call;
   - related seed rows use the ID ranges below (no colliding PKs).
4. Prefer small PRs: one SQL object (+ its test) or one UI screen per PR when possible.

## Shared contracts (schema freeze)

Lock these before parallel tracks diverge:

- Table / column names and types from A1 mapping
- Status enums on `` `ORDER` ``: `IDLE`, `ASSIGNING`, `ACCEPTED`, `IN_PROCESS`, `COMPLETED`, `CANCELLED`
- Payment methods: `CASH`, `CASH_BY_RECIPIENT`, `BALANCE`
- Exact signatures of all Section 2 procedures / functions (see `sql/03_programmability.sql`)

## Seed ID ranges

| Entity | IDs | Notes |
|---|---|---|
| Customers (`ACCOUNT` / `CUSTOMER`) | 1–5 | |
| Drivers | 6–10 | Driver 6 = happy path; 7 = busy; 8 = unverified; 9 = expired docs |
| Staff | 11–15 | |
| Partners | 1–5 | |
| Owners | 1–6 | |
| Orders | 101–108 | Leave headroom for demo inserts |

## Error message convention

Every custom validation failure:

```sql
SIGNAL SQLSTATE '45000'
  SET MESSAGE_TEXT = '[RuleCode] Specific explanation...';
```

Examples:

- `[C8_Eligibility] Driver #9 cannot accept Order #102: Vehicle 59-X1 999.99 insurance expired on 2026-11-03.`
- `[C3_Wallet] Customer #2 available funds (20,000 VND) are below TotalFee (48,000 VND).`
- `[LifecycleError] Customer #1 cannot cancel Order #104 because trip is already IN_PROCESS.`

Flask catches these and shows `MESSAGE_TEXT` in a Bootstrap alert.

## Local MySQL only

Each member installs MySQL locally. No shared Supabase / AWS / Render free-tier DB for the demo (sleep timers, Wi-Fi blocks, latency).

## Google Drive

Code stays in GitHub. Drive holds only the Live Demo Script and Oral Defense Cheat Sheet.
