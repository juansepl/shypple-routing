# Functional Specification

Behavior and verification scenarios belong here; execution status belongs in
`plan.md`. Sources: [challenge](CHALLENGE.md) and
[decisions](ARCHITECTURE-DECISIONS.md). A documented criterion is not evidence of
implementation or a passing test.

**Requirement** means explicit challenge behavior. **Agreed assumption** means
a candidate decision, not PO approval. **Selected policy** is an engineering
choice finalized under the user's authorization to proceed; it does not imply PO approval.

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
- **Agreed decision principle:** when product behavior is undefined, choose a
  conservative business interpretation that minimizes underquoting and operational
  loss risk. If indispensable pricing data is missing or ambiguous and no agreed
  resolution exists, reject the operation rather than inventing a zero price,
  exchange rate or provider priority. Apply established policies first, including
  the higher-valid-quote rule; then preserve the requested cheapest/fastest
  objective. Do not invent fees, buffers, margins or other commercial requirements.
  The feed exposes no cost/margin breakdown, so this principle cannot guarantee
  profitability. The selected working policies below apply this principle without
  changing the requested search objective.
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
not determine the winner. The working policies below are selected for implementation
under the user's authorization; they are not a claim of implemented behavior or PO approval.

### Acceptance Criteria

| Acceptance ID | Observable outcome |
|---|---|
| PLS-0001-AC-01 | Consider only single-leg sailings matching both requested ports; do not compare an indirect route with the direct candidates. |
| PLS-0001-AC-02 | Select the mathematically lowest EUR price after applying the agreed higher-conflict policy and each sailing's departure-date conversion; never round legs to cents before ranking. Apply the deterministic tie rules below only to mathematically equal prices. |
| PLS-0001-AC-03 | Return one chosen leg in the shared format with its original feed values and quote, or `[]` if no direct exists. Success and no-route are normal results; saving requests is outside REQ-01 and belongs to REQ-04. |
| PLS-0001-AC-04 | Reject invalid input or indispensable invalid feed data with a nonzero status and diagnostics on stderr, not a successful route response. Validate the complete catalog, not just matching direct candidates. Apply the validation and process outcomes below. |

### Already Agreed

Use the default three-line CLI, original JSON data/output fields, departure-date
EUR comparison, the higher valid conflicting quote, and strictly positive prices.
Invalid catalog data cannot be silently skipped to make another sailing win.
These rules do not require a date input, live exchange lookup or search persistence
in this ticket. `cheapest` and `fastest` are valid challenge criteria reserved for
REQ-02/03; before their implementation they must not be described as globally
invalid criteria or silently evaluated as `cheapest-direct`.

The order of decisions is explicit:

1. **Same sailing code, unequal quote values:** the already agreed conservative
   rule selects the highest valid EUR-normalized quote. For `MNOP`, USD 812.00
   prevails over USD 456.78. No alphabetical tie-break can override this rule.
2. **Different sailing codes:** compare their selected quotes and choose the
   cheapest direct sailing. Only if those EUR prices are mathematically identical
   does the selected sailing-code tie-break apply.
3. **Same sailing code, mathematically equivalent quotes:** their EUR value is
   already equal. The mechanical original-representation tie-break applies
   below; it does not replace the higher-value policy for unequal quotes.

### Selected Working Policies

The conservative-business principle protects price ordering and rejects indispensable
pricing ambiguity; it does not replace cheapest-direct selection. Exact-equivalent
ties have no price difference: ordering them is reproducibility, not a margin safeguard.

| Decision | Selected policy |
|---|---|
| REQ-01-D-01 — Precision | Parse decimal prices and required exchange numbers exactly, then use exact rational amounts for comparison and route sums (e.g. decimal-to-rational conversion or mathematically equivalent arithmetic). Never rank rounded decimals. This also resolves summed indirect-route precision. |
| REQ-01-D-02 — Deterministic ties | First select the highest valid EUR value among unequal quotes of one sailing. For exactly equal quotes of that sailing, choose the smallest original-string `(rate_currency, rate)` pair. Among distinct equal-price routes, prefer fewer legs, then lexicographic sailing-code sequence; for direct routes this is simply the smallest code. Neither tie rule overrides a higher/lower conflicting-quote comparison. |
| REQ-01-D-03 — Input boundaries | Consume one three-line request and respond after line three without waiting for EOF. Trim fields; normalize ports to uppercase for matching while preserving original feed output. Criteria are case-sensitive after trimming. Missing/blank fields fail; no final newline is required. Ignore further stdin lines. Unknown nonempty ports yield `[]`, without an external port regex. Equal normalized origin/destination is invalid. |
| REQ-01-D-04 — Feed/error boundaries | Validate the whole catalog's required data before ranking; ignore extra fields. Apply the concrete rules and process outcomes below. Empty sailing/rate arrays with an empty exchange object form a valid no-route catalog. |

The catalog must be an object with `sailings`/`rates` arrays and an `exchange_rates`
object. Sailing identifiers/ports are nonblank strings; dates are real ISO
`YYYY-MM-DD` calendar dates with arrival strictly after departure. Later connections
may depart on the previous leg's arrival day (`next_departure >= arrival`).

Each quote references a known sailing, has a nonblank currency and a positive finite
price string of digits with an optional decimal fraction (`123`, `123.45`, `0.50`).
Reject spaces, separators, exponent notation, NaN/infinity, booleans and JSON-number
prices. Do not invent a currency registry. Normalize currency lookup case only and
preserve the original currency in output; EUR uses factor 1. Required non-EUR
exchange values must be positive finite JSON numbers parsed exactly, not through
binary Float. Only required date/currency entries need validation; unused exchange
entries and an absent EUR entry do not add requirements.

Consolidate sailings with identical required fields and the same code; reject
conflicting definitions of a code, orphan quotes and sailings without quotes.
Repeated/conflicting quotes are valid input for the agreed rate policy. Missing
required exchange data anywhere in the catalog fails even when unrelated to the
requested ports. Unknown object fields do not alter output or quote authority.

### CLI Outcomes

`--feed PATH` selects the current catalog for default searches and `--pending`.
Unknown flags, missing flag values, duplicate flags, extra positional arguments or
combining `--pending` with `--ack` fail clearly. These modes do not introduce a
`search` subcommand. Acknowledgment does not require reading the catalog.

| Outcome | stdout | stderr | Exit status |
|---|---|---|---|
| Matching route | Required ordered JSON leg array, original fields/values | Optional diagnostics only | 0 |
| Valid query without a route, including unknown ports | `[]` | Optional diagnostics only | 0 |
| Invalid input, flags, catalog or acknowledgment | Empty | Clear diagnostic; exact wording is not fixed | 1 |
| Recognized `cheapest`/`fastest` before its ticket exists | Empty | Criterion recognized but not implemented in that phase | 1 |

### Test Scenarios

These are selected verification scenarios, not executed test evidence. Existing
IDs are preserved; exercise the real CLI as described under Automated CLI Verification.

| Scenario ID | Input condition → expected behavior | Criteria |
|---|---|---|
| PLS-0001-TC-01 | Cheaper indirect exists → choose cheapest direct only. | AC-01, AC-02 |
| PLS-0001-TC-02 | Mixed currencies/date-specific changes reverse nominal ranking → choose by converted EUR price using each departure date. | AC-02 |
| PLS-0001-TC-03 | `MNOP` has USD 456.78/812.00 in either order → use USD 812.00; the sample query selects `ABCD`. | AC-02 |
| PLS-0001-TC-04 | Quote already in EUR, without EUR exchange entry → compare unchanged and retain original quote. | AC-02, AC-03 |
| PLS-0001-TC-05 | Only indirects or no route exist → `[]`, normal exit; do not persist a search in REQ-01. | AC-01, AC-03 |
| PLS-0001-TC-06 | Valid selection → exactly the seven required string-valued fields, original quote/date values, no diagnostic text in stdout and exit 0. | AC-03 |
| PLS-0001-TC-07 | Missing/blank input or unknown criterion → error; known later criteria are recognized but reported unimplemented until their own tickets. Apply the selected stream/status policy. | AC-04 |
| PLS-0001-TC-08 | Missing quote/change, invalid date or missing/non-numeric/zero/negative price anywhere in the catalog → fail rather than remove a candidate silently. | AC-04 |
| PLS-0001-TC-09 | D-01: `1 / 3` versus EUR `0.3333333333333333333333333334` → the former is cheaper; rounding must not turn them into a tie. Repeat equivalent near-equal comparisons for higher conflicting quotes. | AC-02 |
| PLS-0001-TC-10 | D-02: distinct direct sailings have mathematically equal EUR costs but different durations → choose smallest sailing code regardless of duration or file order. | AC-02, AC-03 |
| PLS-0001-TC-11 | D-02: quotes of the same sailing have exactly equal EUR values but different currencies or decimal spellings → original-string representation tie-break only; unequal quotes still select the higher EUR value. Exact duplicate quotes do not multiply output legs. | AC-02, AC-03 |
| PLS-0001-TC-12 | D-03: lowercase/padded input ports and trimmed criterion, CRLF, or final line without newline → same match; a fourth line is ignored, with no second result or wait for further input. | AC-01, AC-03, AC-04 |
| PLS-0001-TC-13 | D-03: unknown nonempty port → `[]`; equal normalized ports or whitespace-only field → error, not a saved request. | AC-03, AC-04 |
| PLS-0001-TC-14 | D-04: required exchange is zero/negative/nonfinite/wrong type or price format violates the selected grammar → error. Valid unused exchange keys and absent EUR exchange do not block a result. | AC-02, AC-04 |
| PLS-0001-TC-15 | D-04: malformed JSON/required structure, orphan quote, missing quote, impossible calendar date or nonpositive direct duration → error; duplicate identical sailing records consolidate, conflicting sailing definitions fail. | AC-01, AC-03, AC-04 |
| PLS-0001-TC-16 | D-04: unknown extra fields and irrelevant sailings with valid data → same selected response; indispensable invalid data on an irrelevant sailing still fails whole-catalog validation. | AC-02, AC-03, AC-04 |
| PLS-0001-TC-17 | Unknown/malformed/duplicate flags, missing `--feed` value or extra positional arguments → exit 1, empty stdout and diagnostic stderr. | AC-04 |
| PLS-0001-TC-18 | `sailings: []`, `rates: []`, `exchange_rates: {}` → valid no-route result `[]`, exit 0. | AC-03 |

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
| WRT-0002-TC-07 | Catalog contains chronologically feasible sailings that form a positive-cost port cycle → terminate and return the finite cheapest complete route without taking the unnecessary cycle; do not hang or reuse a sailing impossibly. Waiting at the repeated port can replace the cycle, so a repeated-port path need not be selected. | AC-01, AC-02 |
| WRT-0002-TC-08 | Near-equal totals containing repeating converted fractions → choose the exactly cheaper rational sum, without per-leg or total cent rounding. | AC-03 |
| WRT-0002-TC-09 | Onward departure equals prior arrival → connection is feasible; earlier departure is not. | AC-02 |
| WRT-0002-TC-10 | Exact equal total costs → prefer fewer legs, then lexicographic code path, independent of catalog order. | AC-01, AC-03, AC-04 |

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
| TST-0003-TC-07 | Exact equal total duration → prefer fewer legs, then lexicographic code path; price does not break a duration tie. | AC-02, AC-03 |

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
| SLD-0004-TC-09 | Repeat an identical pending query → reuse its request; after it resolves and a later catalog cannot fulfill it, a new query may create a new pending request. | AC-01, AC-03 |
| SLD-0004-TC-10 | `--ack` with malformed/nonpositive, unknown or unresolved ID → error without state changes; resolved ID succeeds and repeated acknowledgment is idempotent. | AC-04, AC-05 |
| SLD-0004-TC-11 | `--pending --ack ID`, duplicate mode flags or missing values → clear CLI error without consuming stdin or mutating records. | AC-02, AC-05 |

### Selected Pending-Review Interface

Use isolated temporary databases/test volumes. `--pending` does not read search
stdin and returns an object with exactly `pending` and `available` arrays. A request
record contains `id` (positive integer), `origin_port`, `destination_port`, `criterion`
and `created_at` (strings). Each `available` record has those fields plus `result`,
the selected leg array. With no requests/notices, return
`{"pending":[],"available":[]}`. Unresolved requests remain in `pending`; resolved
unacknowledged requests remain in `available` across runs.

`--ack ID` takes a positive base-10 integer, marks a resolved result acknowledged,
and returns `{"id":ID,"acknowledged":true}`. Repeating acknowledgment of the same
resolved ID returns the same success. Unknown IDs, unresolved request IDs, invalid
IDs and combined pending/ack modes produce the error outcome above without mutation.
There is no separate `notifications` subcommand.

Reuse one pending request for an identical normalized origin/destination/criterion
tuple. Once that request is resolved, a new unsuccessful search of the same tuple
may create a new pending request. Read the updated catalog on each normal search
and review; acknowledging an older result cannot remove a route from the catalog.

The storage schema is an implementation choice. One SQLite table with request
fields, nullable `result`, and an acknowledged flag is sufficient: setting `result`
atomically resolves the search and makes its notice available. Two tables are not
a requirement. A failed resolution write must leave the request pending; output
is printed after the state change succeeds.


## Automated CLI Verification

The scenarios below define acceptance verification; their definitions are not
execution evidence. Record actual results in `plan.md` against the criterion and
scenario IDs above.

- Implement Minitest integration tests inside Docker that start the real
  `bin/app` in a separate Ruby process. **Selected mechanism:** standard-library
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
  inspect its parsed result, then acknowledge through `--ack ID`.
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

## Policy Status

REQ-01-D-01 through D-04 and the pending-review interface are selected working
policies under the user's authorization to proceed. They are candidate engineering
choices, not PO-confirmed business rules. No product-policy decision above blocks
implementation. Algorithm/class layout and database schema remain proportional
implementation choices; they must preserve these observable outcomes.

## Scope Boundaries

Delivery covers the four-ticket Ruby/Docker CLI, tests and documented assumptions.
No web UI, remote feed service, customer accounts, background notification or catalog
versioning is required. `--explain` is deferred optional work and cannot alter the
default JSON. DRY-0005/TDD-0006 are future tickets. ZIP preparation is a delivery
step; sending email or publishing requires separate authorization.
