# Functional Specification

Behavior and verification scenarios belong here; execution status belongs in
`plan.md`. Sources: [challenge](CHALLENGE.md) and
[decisions](ARCHITECTURE-DECISIONS.md). A documented criterion is not evidence of
implementation or a passing test.

**Requirement** means explicit challenge behavior. **Agreed assumption** means
a candidate decision, not PO approval. **Open proposal** must be settled before
implementing affected behavior.

## Requirement IDs

Use these aliases for the implementation plan and commit messages. Keep the
original ticket IDs in acceptance criteria and scenarios for traceability.

| Requirement | Original ticket | Behavior |
|---|---|---|
| REQ-01 | PLS-0001 | Cheapest direct route |
| REQ-02 | WRT-0002 | Cheapest complete route |
| REQ-03 | TST-0003 | Fastest complete route |
| REQ-04 | SLD-0004 | Save searches and review pending results |

## Shared Contract

- **Requirement:** Ruby application runnable with Docker-only prerequisites;
  three stdin lines: origin port, destination port, criterion (`cheapest-direct`,
  `cheapest`, `fastest`). One branch contains all changes.
- **Requirement:** return all chosen legs in travel order as a JSON array, with
  only `origin_port`, `destination_port`, `departure_date`, `arrival_date`,
  `sailing_code`, `rate`, `rate_currency`. Preserve original price strings and
  currencies rather than returning normalized prices.
- **Requirement:** join sailing/rate by `sailing_code`. Convert each leg to EUR
  using its departure-date exchange rate: original price divided by foreign
  currency units per EUR. EUR needs no conversion. Compare normalized totals.
- **Agreed assumptions:** default search has no `search` subcommand or date input;
  stdout contains only JSON, diagnostics use stderr. No route returns `[]`.
  Invalid input or indispensable invalid feed data produces a nonzero error,
  not a successful missing-route request. JSON values override illustrative
  README examples; written challenge rules still define behavior.
- **Agreed assumptions:** for conflicting valid quotes with unknown authority,
  use the highest EUR-normalized quote per sailing before comparing routes.
  Keep its original amount/currency. Do not add competing quotes together or
  depend on their order. This reduces underquoting risk, not proof of validity.
- **Agreed quality policy:** every sailing needs a numeric price greater than
  zero and its currency. Validate dates, references and necessary exchange rates;
  invalid data stops the operation without modifying saved requests/notices.
  Do not silently omit candidates or substitute another day's exchange rate.
- **Agreed interpretation:** connections require matching ports and feasible
  dates; the next sailing cannot leave before the preceding one arrives. Total
  journey time includes waits. Use catalog dates, not today's date. Indirect
  routes must support more than two legs, as explicitly required.

## REQ-01 / PLS-0001 — Cheapest Direct Sailing

Find the cheapest single-leg route between the requested ports. Duration does
not determine the winner.

| Acceptance ID | Observable outcome |
|---|---|
| PLS-0001-AC-01 | Consider only single-leg sailings matching both requested ports. |
| PLS-0001-AC-02 | Select the lowest EUR price after conflict resolution and departure-date conversion. |
| PLS-0001-AC-03 | Return one chosen leg in the shared format, or `[]` if no direct exists. |
| PLS-0001-AC-04 | Invalid input/feed produces an error without a successful route response. |

| Scenario ID | Input condition → expected behavior | Criteria |
|---|---|---|
| PLS-0001-TC-01 | Cheaper indirect exists → choose cheapest direct only. | AC-01, AC-02 |
| PLS-0001-TC-02 | Mixed currencies/date-specific changes reverse nominal ranking → choose by converted EUR price using each departure date. | AC-02 |
| PLS-0001-TC-03 | `MNOP` has USD 456.78/812.00, in either order → use USD 812.00. | AC-02 |
| PLS-0001-TC-04 | Quote already in EUR, without EUR exchange entry → compare unchanged; retain original quote. | AC-02, AC-03 |
| PLS-0001-TC-05 | Only indirects or no route exist → `[]`; persistence is added in SLD-0004. | AC-01, AC-03 |
| PLS-0001-TC-06 | Valid selection → exact required fields, string rate and no diagnostic text in stdout. | AC-03 |
| PLS-0001-TC-07 | Missing input line/unsupported criterion → nonzero error. | AC-04 |
| PLS-0001-TC-08 | Missing quote/change, invalid date or missing/non-numeric/zero/negative price → fail, not silent candidate removal. | AC-04 |

## REQ-02 / WRT-0002 — Cheapest Complete Route

Find the lowest total price among valid direct and indirect routes.

| Acceptance ID | Observable outcome |
|---|---|
| WRT-0002-AC-01 | Compare direct and indirect routes, including three or more legs. |
| WRT-0002-AC-02 | Connections match ports and respect arrival/departure chronology. |
| WRT-0002-AC-03 | Minimize the sum of individually converted leg prices under shared rate rules. |
| WRT-0002-AC-04 | Return all selected legs in travel order, or `[]` if no valid route exists. |

| Scenario ID | Input condition → expected behavior | Criteria |
|---|---|---|
| WRT-0002-TC-01 | Two-leg route is cheaper than every direct → return both legs. | AC-01, AC-03, AC-04 |
| WRT-0002-TC-02 | Direct is cheapest overall → return one leg. | AC-01, AC-03, AC-04 |
| WRT-0002-TC-03 | Only/cheapest route has at least three legs → return it without a two-leg cap. | AC-01, AC-04 |
| WRT-0002-TC-04 | Intermediate ports differ, or onward departure precedes arrival → exclude the connection. | AC-02 |
| WRT-0002-TC-05 | Legs have different currencies/dates → rank by their converted sum without rounding each leg to cents. | AC-03 |
| WRT-0002-TC-06 | Sailings exist but no complete feasible path → `[]`. | AC-02, AC-04 |
| WRT-0002-TC-07 | A feasible path revisits a port later → do not reject solely for repeated ports; disallow temporally impossible sailing reuse. | AC-01, AC-02 |

## REQ-03 / TST-0003 — Fastest Complete Route

Find the shortest elapsed journey, irrespective of price. Including waits is our
interpretation of the challenge's total-journey definition.

| Acceptance ID | Observable outcome |
|---|---|
| TST-0003-AC-01 | Consider valid direct and indirect routes, including more than two legs. |
| TST-0003-AC-02 | Minimize final arrival minus first departure, including connection waits; ignore price when comparing durations. |
| TST-0003-AC-03 | Return all chosen legs with original quotes, or `[]` if no feasible route exists. |

| Scenario ID | Input condition → expected behavior | Criteria |
|---|---|---|
| TST-0003-TC-01 | Indirect is faster than all directs → choose it. | AC-01, AC-02, AC-03 |
| TST-0003-TC-02 | Shorter sailing-only time has a longer wait → choose shortest full elapsed journey. | AC-02 |
| TST-0003-TC-03 | Cheapest, earliest arrival and shortest duration differ → choose shortest duration. | AC-02 |
| TST-0003-TC-04 | Three-or-more-leg route is fastest → return every leg. | AC-01, AC-03 |
| TST-0003-TC-05 | All possible connections leave too early → exclude them and return `[]` if none remain. | AC-01, AC-03 |
| TST-0003-TC-06 | Different partial paths reach the same onward sailing → choose shortest complete journey, not merely a locally shortest segment. | AC-02 |

## REQ-04 / SLD-0004 — Save Now, Fulfill Later

Save valid searches without a matching route and surface them when new catalog
data allows fulfillment. Persistence is an explicit requirement; the manual
interface and notification lifecycle below are agreed solution choices.

| Acceptance ID | Observable outcome |
|---|---|
| SLD-0004-AC-01 | Store origin/destination/criterion for a valid unsuccessful search, return `[]`, and preserve the request across containers sharing its volume. |
| SLD-0004-AC-02 | `--pending` takes no search stdin, reviews current data using each saved criterion, and shows unresolved requests and available unacknowledged results. |
| SLD-0004-AC-03 | A newly resolved request stops being reevaluated and creates one recoverable notification with selected legs; repeated reviews do not duplicate it. |
| SLD-0004-AC-04 | Display does not acknowledge a notice. Explicit acknowledgment removes it from pending notices; repetition is harmless and route availability is unchanged. |
| SLD-0004-AC-05 | Resolution and notice creation are atomic. Invalid catalog/input does not mutate requests/notices or become a missing-route request. |
| SLD-0004-AC-06 | New catalog routes are available to normal searches before manual review; use one catalog without version history or background processes. |

| Scenario ID | Input condition → expected behavior | Criteria |
|---|---|---|
| SLD-0004-TC-01 | Search misses; exit and start another container with the same isolated test volume → request remains pending. | AC-01 |
| SLD-0004-TC-02 | Updated catalog satisfies requests for each criterion → review uses the original criteria and returns their selected legs. | AC-02 |
| SLD-0004-TC-03 | Updated data still cannot fulfill a request → keep it pending. | AC-02 |
| SLD-0004-TC-04 | Repeat review after resolution → one notification, still recoverable until acknowledged. | AC-03, AC-04 |
| SLD-0004-TC-05 | Display then restart → notice remains unacknowledged; acknowledge and repeat → stays acknowledged without error. | AC-04 |
| SLD-0004-TC-06 | Notice creation fails → roll back resolution. Invalid catalog/input → no mutation. | AC-05 |
| SLD-0004-TC-07 | Add a route, then search before reviewing → new route is available. | AC-06 |
| SLD-0004-TC-08 | No requests/notices exist → valid empty administrative result without search stdin. | AC-02, AC-04 |

Use isolated temporary databases/test volumes. Define administrative JSON and
acknowledgment details before implementing affected scenarios.

## Automated CLI Verification

The following verification is **pending**, not executed acceptance: `bin/app` is
currently a scaffold with no routing behavior. Record future execution evidence
in `plan.md`; retain the existing criterion/scenario mappings above.

- Implement Minitest integration tests inside Docker that start the real
  `bin/app` in a separate Ruby process. **Proposed mechanism:** standard-library
  `Open3.capture3` with `RbConfig.ruby`, capturing stdout, stderr and process status.
  Feed the three input lines through stdin, not direct calls to route classes.
- Parse stdout as JSON and assert the selected route against the controlled
  fixture: exact leg fields, string values including `rate`, original currency,
  correct dates and leg order. Check stdout contains no diagnostic text, stderr
  carries diagnostics when applicable, and the process has the expected exit code.
- REQ-01/02/03 must exercise the sample winners below through that interface,
  plus scenario-specific fixtures for conversion, connections, duration and
  multiple legs. Also check no-route output (`[]`) and invalid-input failures as
  processes. Saving unsuccessful requests is required only once REQ-04 is built.
- REQ-04 must run multiple CLI processes against one isolated persistent test
  database: save a missing route, update a temporary catalog, invoke `--pending`,
  inspect its parsed result, then acknowledge after that interface is settled.
  Recheck recovery, deduplication and unchanged state on invalid data. Separately
  verify container replacement using a dedicated test volume; process restarts
  alone do not establish Docker-volume persistence. Never mutate the development
  database, volume or original catalog during these tests.

Unit tests complement these console checks; they do not replace CLI acceptance.
Coverage percentage does not prove the output contract. Separate Ruby processes
need explicit coverage instrumentation to contribute to SimpleCov results.

## Sample Reference Outcomes

For `CNSHA → NLRTM` in `fixtures/response.json`, under the higher-conflict policy:
`cheapest-direct` → `ABCD`; `cheapest` → `ERXQ`, `ETRG`;
`fastest` → `QRST` (17 days). These are analysis references, not executed tests.

## Open Proposals

Resolve each before implementing affected behavior, and update the applicable
decision with the contract. Do not promote these proposals silently.

| Topic | Proposal / clarification needed |
|---|---|
| Money | Division precision and near-equal totals; no per-leg cent rounding. |
| Ties | Fewer legs, then lexicographic code sequence; specify equivalent quote ties. |
| Date boundaries | Same-day connections allowed, strictly positive leg duration; not yet settled. |
| Duplicate sailings | Consolidate identical records, reject one code with incompatible dates/routes. Rate conflicts already have an agreed policy. |
| Input boundaries | Whitespace/case normalization, malformed/unknown ports and origin equal to destination; no assumed mandatory port-code regex. |
| Administrative interface | `--pending` JSON and empty result, acknowledgment action and unknown IDs. `--feed PATH`, `notifications`, `acknowledge ID` remain proposed. |
| Request identity | Reuse of equivalent pending requests and new requests after older resolution; proposed SQL schema is not itself a business requirement. |

## Scope Boundaries

Delivery covers the four-ticket Ruby/Docker CLI, tests and documented assumptions.
No web UI, remote feed service, customer accounts, background notification or catalog
versioning is required. `--explain` is deferred optional work and cannot alter the
default JSON. DRY-0005/TDD-0006 are future tickets. ZIP preparation is a delivery
step; sending email or publishing requires separate authorization.
