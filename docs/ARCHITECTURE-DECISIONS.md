# Architecture Decisions

Implementation is proceeding ticket by ticket; current progress and evidence are
recorded in plan.md.
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

Agreed general policy: unspecified product decisions must be conservative toward
business risk, reducing underquoting and potential operational losses. Do not
invent prices, exchange rates or margins when indispensable data is missing.
Explain trade-offs and flag unresolved ambiguity. This does not change the search
criterion or guarantee profitability; the feed does not expose actual margins.

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
Convert exact decimal inputs to rational EUR values for ranking and summing.
This avoids an arbitrary division precision or rounded-price ties. Output original
amounts and currencies, not converted prices.

## ADR-005 — Dates

Use catalog dates, not today's date. Journey duration is final arrival minus first
departure. Including connection waits is our interpretation of “total journey time.”
Allow same-day connections, require positive leg duration and treat
dates as calendar days. A next leg cannot depart before the previous arrival.

## ADR-006 — Stack, tests and coverage

Use Ruby 4.0.9, Bundler 4.0.20, sqlite3 2.10.1, Minitest 6.0.6 and SimpleCov 1.3.2.
The observed SQLite engine is 3.54.1. Pin the Docker image by digest and dependencies
with Gemfile.lock. Build and runtime checks passed on ARM64.

Minitest and SimpleCov are test-group dependencies. `bin/test` loads the helper
before discovering `test/**/*_test.rb`. Start coverage before loading application
code. Report `bin/app` and `lib/**/*.rb`, including unloaded files; exclude test
infrastructure and dependencies. Generate HTML under `coverage/`, merging instrumented CLI subprocesses from the
current suite but clearing older suite results. No minimum percentage is imposed.
Execution counts and coverage results belong in plan.md.

Tests use `minitest/spec` (`describe`/`it`) with `assert_*`, without extra gems.
Each ticket has one acceptance file in `test/acceptance/` that runs the real `bin/app`
in a separate Ruby process; its `describe` titles cite the criterion IDs in spec.md.
Unit specs in `test/unit/` cover detailed rules, mostly with in-memory data.

## ADR-007 — Separate calculation from I/O

Route and price rules work with prepared data. Keep file reading, SQLite access
and console output separate. Reuse the route finder for searches and pending
reviews. Add coordination classes only when useful; no mandatory extra layers.

Object roles: value objects (`Sailing`, `Quote`, `Leg`, `Route`, `SearchRequest`);
`Feed::JsonSource`, the feed parsers and `Catalog` build legs from the JSON file;
`RatePolicy::HighestQuote` applies ADR-003; criteria are strategies (ADR-012);
`RouteFinder` searches; `RouteSerializer` owns the seven output fields; `CLI::OptionsParser`
parses flags and forms validate stdin and the `--ack` ID; each service runs one use case;
`Persistence::SavedSearchRepository` holds the SQL (ADR-008). `CLI::Application` is the
only place that wires files, SQLite and the console. `Shypple::Error` subclasses and
file-system, stored-JSON and SQLite errors exit 1 with their message on stderr; other
exceptions are programming errors and are not rescued.

## ADR-008 — Storage

Use one current JSON catalog, without versions or catalog copies in SQLite. The
SQLite file lives at `/app/data/shypple.sqlite3`, mounted through the
`shypple-routing-data` volume.

Use one SQLite table for request details, a nullable result and an acknowledgment
flag. A missing result is pending; a stored result is resolved and visible until
acknowledged. One atomic result update resolves the request and creates its notice,
without a second table. Deduplicate equivalent pending requests, but allow a new
request after a prior one resolves. Catalog updates remain separate. Use parameterized SQL.

SQL lives only in `Persistence::Schema` and `Persistence::SavedSearchRepository`,
which opens the database on first use. Pending review and acknowledgment are services
that depend on the repository's methods, not on SQLite.

## ADR-009 — Manual pending review

`--pending` reads the current catalog, reviews saved requests and shows unresolved
requests plus available, unacknowledged results. No stdin input or background
process is needed. New catalog routes are also available to normal searches.

`--feed PATH` selects the shared catalog file. `--pending` returns `pending` and
`available` arrays; each available record includes its result. `--ack ID` confirms
a resolved request and is idempotent. Reject unknown/unresolved IDs and combined
modes. No separate notifications command is needed. Exact fields are in spec.md.

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
Consolidate identical duplicates and reject a sailing code with
incompatible routes or dates. The sample has nine sailings, ten rates and all
required exchanges; only `MNOP` has conflicting rates.

## ADR-012 — Connect compatible legs

Process sailings chronologically and retain one best path per reachable sailing:
minimum accumulated cost for `cheapest`, latest initial departure for `fastest`.
Ports and dates determine valid connections. No artificial two-leg limit or
blanket ban on revisiting ports is needed.

Selected ties: fewer legs, then lexicographic sailing-code sequence. Equal-value
quotes of one sailing use the smallest original currency/amount string pair only
after applying the higher-price rule. The compact implementation scans earlier
paths instead of building an explicit graph. With N sailings and path length L,
worst-case work is O(N²L), plus exact-number arithmetic; retained paths use O(NL)
space. This avoids enumerating exponentially many itineraries. Cache path keys or
index connections only if larger feeds justify the extra code.

Each criterion is a strategy object registered by name in `Criteria`. It supplies its
ranking keys, so `RouteFinder` never branches on criterion names; a new criterion
adds one class and one registry entry.

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
