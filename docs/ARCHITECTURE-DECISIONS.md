# Architecture Decisions

The base is implemented; the four functional tickets are pending.
Decisions below are agreed with the candidate unless marked
**proposed**; they are not PO approval. Rate handling and source-of-truth assumptions
were emailed to the PO; no response has been recorded.

## ADR-001 — Search input and output

Read three stdin lines: origin, destination and criterion. Search is the default
operation, with no `search` subcommand or date input.

| Criterion | Meaning |
|---|---|
| `cheapest-direct` | Cheapest single-leg route between the ports. |
| `cheapest` | Cheapest complete route, direct or with connections. |
| `fastest` | Shortest complete journey, regardless of price. |

Return the selected legs in order as a JSON array, using only `origin_port`,
`destination_port`, `departure_date`, `arrival_date`, `sailing_code`, `rate` and
`rate_currency`. Keep the original rate string and currency. Diagnostics go to stderr.
No route: return `[]` and save the request once SLD-0004 is implemented. Invalid
input or catalog data is an error, not a missing route.

## ADR-002 — Source of truth

Use JSON values when they differ from README examples. Functional rules still
come from the exercise. Keep the original fixture unchanged.

## ADR-003 — Conflicting rates

When priority or validity is unknown, select the higher valid rate per sailing
before comparing routes. This reduces underquoting risk but may reduce
competitiveness. Compare different currencies in EUR; retain the selected original
quote. Do not depend on file order or add conflicting quotes together.

For `MNOP`, select USD 812.00 rather than USD 456.78. Under this policy, the sample
`CNSHA → NLRTM` results should be:

| Criterion | Goal | Expected result |
|---|---|---|
| `cheapest-direct` | Cheapest direct, single-leg option | `ABCD`, about EUR 523.36 |
| `cheapest` | Cheapest total across all valid routes | `ERXQ → ETRG`, about EUR 322.89 |
| `fastest` | Shortest total duration, including waits | `QRST`, 17 days |

These are calculated reference values; ticket tests remain pending.

## ADR-004 — Money

Join rates by `sailing_code`. Convert each leg using its departure-date exchange
rate: `amount_eur = original_amount / exchange_rate`. EUR uses factor 1. Use
`BigDecimal`, avoid `Float`, and do not round legs to cents before ranking routes.
Division precision will be defined during implementation. Output original amounts
and currencies, not converted prices.

## ADR-005 — Dates

Use catalog dates, not today's date. Journey duration is final arrival minus first
departure. Including connection waits is our interpretation of “total journey time.”
**Proposed:** allow same-day connections, require positive leg duration and treat
dates as calendar days. A next leg cannot depart before the previous arrival.

## ADR-006 — Stack, tests and coverage

Use Ruby 4.0.9, Bundler 4.0.20, sqlite3 2.10.1, Minitest 6.0.6 and SimpleCov 1.3.2.
The observed SQLite engine is 3.54.1. Pin the Docker image by digest and dependencies
with Gemfile.lock. Build and runtime checks passed on ARM64.

Minitest and SimpleCov are test-group dependencies. `bin/test` loads the helper
before discovering `test/**/*_test.rb`. Start coverage before loading application
code. Report `bin/app` and `lib/**/*.rb`, including unloaded files; exclude test
infrastructure and dependencies. Generate HTML under `coverage/`, without merging
older results or enforcing a minimum percentage. Separate Ruby processes require
separate instrumentation. Current result: zero tests, 0/9 covered lines (0.00%).

## ADR-007 — Separate calculation from I/O

Route and price rules work with prepared data. Keep file reading, SQLite access
and console output separate. Reuse the route finder for searches and pending
reviews. Add coordination classes only when useful; no mandatory extra layers.

## ADR-008 — Storage

Use one current JSON catalog, without versions or catalog copies in SQLite. The
SQLite file lives at `/app/data/shypple.sqlite3`, mounted through the
`shypple-routing-data` volume.

**Proposed schema:** `saved_searches` holds request details and `pending`/`resolved`
status; `notifications` holds selected legs and `pending`/`acknowledged` status.
Deduplicate equivalent pending requests and create one notification per resolved
request. Resolve a search and create its notification in one transaction. Catalog
file updates are separate. Enable foreign keys and use parameterized SQL.

## ADR-009 — Manual pending review

`--pending` reads the current catalog, reviews saved requests and shows unresolved
requests plus available, unacknowledged results. No stdin input or background
process is needed. New catalog routes are also available to normal searches.

**Proposed:** `--feed PATH` selects the shared catalog file; `notifications` lists
notices and `acknowledge ID` confirms one. Define administrative JSON in SLD-0004,
without changing the required search output.

## ADR-010 — Resolved versus seen

A request becomes resolved when a route is found; its notice remains pending
until explicitly acknowledged. Displaying a result does not mark it seen. Preserve
notices across runs and avoid duplicates on repeated reviews. Acknowledgment is
idempotent and does not affect route availability. Scope is one local consumer.

## ADR-011 — Feed quality

Validate sailing/rate references, dates, prices, currencies and required departure-date
exchange rates. Each leg must have a numeric price greater than zero, so its value
is not omitted or understated. This is our quality policy, not an explicit rule
in the exercise. EUR needs no exchange entry.

Invalid data stops the operation without changing searches or notices. Do not
silently omit candidates or substitute another day's exchange rate.
**Proposed:** consolidate identical duplicates and reject a sailing code with
incompatible routes or dates. The sample has nine sailings, ten rates and all
required exchanges; only `MNOP` has conflicting rates.

## ADR-012 — Connect compatible legs

**Proposed:** represent sailings as a temporal graph connected by ports and dates.
Use dynamic programming: minimum accumulated cost for `cheapest`, latest initial
departure per reachable sailing for `fastest`; retain predecessors to reconstruct
the route. No artificial two-leg limit or blanket ban on revisiting ports.

Proposed ties: fewer legs, then lexicographic sailing-code sequence. Initial edge
construction can be O(N²), followed by O(N + E) traversal, plus reconstruction and
tie-breaking costs.

## ADR-013 — Delivery steps

Use one branch. Separate the base, AI workflow configuration and initial
specification/plan into their own commits, then deliver one functional commit per
requirement with tests and progress updates. `REQ-01` through `REQ-04` map to the
original challenge tickets in `spec.md`. Follow the sequence in `../plan.md`.
Run relevant checks and existing tests before closing a ticket. The base contains
configuration, not functional tests.

## ADR-014 — Optional explanation

After the required tickets, `--explain` may show the itinerary and summary on
stderr while preserving JSON on stdout. Keep selected legs, original/converted
prices, exchange rates and conflict decisions in the internal result; derive
travel and waiting times from dates. Reuse those calculations without rerunning
selection. Do not store every rejected route. Extra persisted calculation details
for explaining older results remain optional.

Project documentation is maintained in English.
