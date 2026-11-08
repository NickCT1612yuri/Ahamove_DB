# Per-track work packs (review-and-fix)

These folders hold **full draft implementations** for each track. They are **not** auto-merged into `sql/02_seed.sql`, `sql/03_programmability.sql`, or `app/`. Owners review, fix, then merge on their `track-*` branch.

## Folders

| Folder | Branch | Owns |
|---|---|---|
| `TRACK_A/` | `track-a-order-crud` | §2.1 CRUD + order seed + §3.1 notes |
| `TRACK_B/` | `track-b-wallet-triggers` | Derived fee/balance triggers + wallet seed |
| `TRACK_C/` | `track-c-eligibility-fleet` | C8 triggers + fleet function + fleet seed |
| `TRACK_D/` | `track-d-search-ui` | Search proc + staff/partner seed + §3.2 notes |
| `TRACK_E/` | `track-e-analytics-fn` | KPI + settlement + city/service seed + §3.3 notes |

Each folder:

1. `01_seed_fragment.sql`
2. `02_programmability.sql`
3. `03_tests.sql`
4. `04_flask_notes.md`
5. `05_oral_defense.md`

## Preferred merge / load order (FK-safe)

After `01_schema.sql` is loaded:

1. **TRACK_B** seed (SPECIAL_REQUEST, ACCOUNT, CUSTOMER) — skip or comment TRANSACTION/ORDER_REQUEST until orders exist, or load with `FOREIGN_KEY_CHECKS=0` then re-enable  
2. **TRACK_D** seed (STAFF, PARTNER, roles)  
3. **TRACK_C** seed (OWNER, DRIVER, VEHICLE, docs, OPERATION)  
4. **TRACK_E** seed (CITY, SERVICE, SERVICE_REQUEST)  
5. **TRACK_A** seed (PROMOTION, ORDER, PATH_POINT, items, photos)  
6. **TRACK_B** remainder (TRANSACTION, ORDER_REQUEST)  
7. All tracks’ `02_programmability.sql` (order: B triggers after A procs if you prefer; any order is OK if using DROP IF EXISTS)  
8. Run each track’s `03_tests.sql`

Or: concatenate seeds with `SET FOREIGN_KEY_CHECKS=0` for a first integration smoke test, then tighten.

## Review checklist (every owner)

- [ ] Seed respects ID contract in `CONTRIBUTING.md`
- [ ] Procedure/function signatures match frozen `sql/03_programmability.sql`
- [ ] Failure paths use `SIGNAL SQLSTATE '45000'` with `[RuleCode] …`
- [ ] Happy + failure demos in `03_tests.sql` run on a clean DB
- [ ] You can explain every rule aloud (see `05_oral_defense.md`)
- [ ] Merge into canonical files; open PR to `main`

## Disclaimer

Drafts are starting points for the team to **review and fix**. Do not submit code you cannot explain.
