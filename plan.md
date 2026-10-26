# Implementation Plan

This file tracks progress and execution evidence. Functional requirements and
test scenarios belong in [docs/spec.md](docs/spec.md); working rules are in
[AGENTS.md](AGENTS.md). Do not duplicate their contracts here.

## Phases

| Phase | Scope | Dependencies | State |
|---|---|---|---|
| 0 | Project base | None | accepted |
| Workflow setup | Orchestrator, specialized roles and SDD rules | Base | accepted |
| Specification setup | Initial requirements, scenarios and implementation plan | Workflow setup | accepted |
| REQ-01 | PLS-0001: cheapest direct route | Base and reviewed active specification | accepted |
| REQ-02 | WRT-0002: cheapest direct or indirect route | REQ-01 | accepted |
| REQ-03 | TST-0003: fastest direct or indirect route | REQ-02 | accepted |
| REQ-04 | SLD-0004: saved searches and manual pending review | All three criteria | accepted |
| Delivery | Full acceptance, usage documentation and ZIP | All four tickets | accepted |

States: `pending`, `in_progress`, `needs_review`, `changes_requested`, `accepted`,
`blocked`. Apply the transition rules in AGENTS.md. A specification draft is not
an implemented feature; a test run with zero cases is not ticket acceptance.

## Commit Sequence

The planned initial sequence has **seven commits**: one base, one AI workflow,
one specification/plan and four functional requirements. The base and workflow
commits are recorded below; the initial specification/plan was committed separately.
Functional commits are recorded below as each validated requirement is committed.

| Order | Message / scope | Commit status |
|---|---|---|
| 1 | Project bootstrap: Ruby, Docker, SQLite and test framework | Committed as `38965f2`; preserve the existing commit |
| 2 | `chore: configure AI-assisted development workflow` — AGENTS.md, role instructions and SDD rules | Committed as `d2324db` |
| 3 | `docs: define requirements and implementation plan` — docs/spec.md, plan.md and their README links | Committed as `fc714f2` |
| 4 | `feat: implement REQ-01 with automated tests` — code, tests and progress | Committed as `9af4ee0` |
| 5 | `feat: implement REQ-02 with automated tests` — code, tests and progress | Committed as `5329541` |
| 6 | `feat: implement REQ-03 with automated tests` — code, tests and progress | Committed as `e1152f2` |
| 7 | `feat: implement REQ-04 with automated tests` — code, tests and progress | Included in this commit; Docker suite and independent review passed |

Include necessary architecture and usage-documentation updates with the change
they describe. Keep workflow configuration separate from the initial functional
specification and plan. Do not create commits until requested by the user.

## Phase 0 — Project Base

- [x] Ruby 4.0.9 and dependencies locked.
- [x] Docker image builds and starts.
- [x] SQLite persists across separate containers using a named volume.
- [x] Minitest runner and SimpleCov configured.
- [x] English README and architecture decisions available.
- [x] Base committed as `38965f2` on branch `exercise`.

Observed baseline checks (already performed, not rerun by this document):

| Check | Result | Scope |
|---|---|---|
| Docker build and startup | passed | Linux ARM64; Ruby 4.0.9, sqlite3 gem 2.10.1, SQLite 3.54.1 |
| Persistent SQLite | passed | Write/read from different containers; integrity check returned `ok` |
| Minitest and coverage generation | passed (configuration only) | Zero project tests; 0/9 covered lines (0.00%) |
| Failed-test exit propagation | passed | Temporary container-only failing assertion returned exit code 1; no project test added |

## Workflow Setup

- [x] Orchestrator and specialized role instructions drafted.
- [x] Documentation consistency reviewed.
- [x] README linked to workflow documents.

This phase creates guidance, not an automated agent framework. No production
changes or functional test cases belong to it. Do not commit it without a user request.

## Specification Setup

- [x] Initial specification and scenario mappings drafted by Requirements Analyst.
- [x] Requirement aliases mapped to original challenge tickets.
- [x] Specification and plan consistency reviewed.
- [x] Initial documentation changes accepted after review.

The initial workflow/specification documents were reviewed before implementation.
The contract was subsequently refined to 17 acceptance criteria and 46 scenarios;
working policies and their implementation were reviewed per ticket below. Setup
acceptance alone is not functional evidence.

## Phase 1 — PLS-0001

Status: **accepted after implementation and independent review**. Working policies
were finalized under the authorization to complete the solution. The validated requirement is included in its dedicated functional commit.

- [x] Specify active criteria and map test scenarios (analysis draft).
- [x] Settle relevant proposed behavior before affected tests are written.
- [x] Write Minitest cases and confirm expected failures.
- [x] Implement the ticket and verify affected tests plus the existing suite.
- [x] Run real CLI acceptance cases for success, no route and invalid input.
- [x] Reviewer accepts the scoped change, or findings are corrected and rechecked.
- [x] Update progress and retain the reviewed change for commit preparation.
- [x] Create the validated ticket commit at the user's request.

The four original acceptance IDs are preserved. Exact pricing, deterministic ties,
input/feed boundaries and the conservative higher-quote policy are finalized in
spec.md. The original query selects `ABCD`, about EUR 523.357016, while output keeps
its original 589.30 USD quote.

## Phase 2 — WRT-0002

Status: **accepted after implementation and independent review**. Exact rational
sums, same-day connections and route ties match docs/spec.md.

- [x] Refine its criteria and connection scenarios.
- [x] Write tests and confirm expected failures.
- [x] Implement and verify the ticket and existing behavior.
- [x] Run real CLI cases asserting the selected multi-leg route and process contract.
- [x] Resolve review findings and record acceptance evidence.
- [x] Update progress and retain the reviewed change for commit preparation.
- [x] Create the validated ticket commit at the user's request.

Additional checks: the reviewer independently matched an exhaustive oracle on
200 deterministic generated catalogs; the orchestrator also matched 16 generated
catalogs through actual Docker CLI processes (seed 814). No routing defects found.

## Phase 3 — TST-0003

Status: **accepted after implementation and independent review**. Elapsed journey
time includes waits; direct and indirect routes participate regardless of price.

- [x] Refine its criteria and elapsed-time scenarios.
- [x] Write tests and confirm expected failures.
- [x] Implement and verify the ticket and existing behavior.
- [x] Run real CLI cases asserting elapsed-time selection and the process contract.
- [x] Resolve review findings and record acceptance evidence.
- [x] Update progress and retain the reviewed change for commit preparation.
- [x] Create the validated ticket commit at the user's request.

Independent reviewer accepted the phase and matched an exhaustive fastest-route
oracle across 200 deterministic generated catalogs. Persistence is not part of
this acceptance.

## Phase 4 — SLD-0004

Status: **accepted after implementation and independent review**. The selected
manual flags and one-table SQLite model were also verified across real containers.

- [x] Finalize the administrative interface and persistence behavior in the spec.
- [x] Write state-transition and cross-execution scenarios and tests.
- [x] Confirm expected failures, then implement using isolated test databases.
- [x] Verify the full suite and repeated manual-review behavior.
- [x] Exercise search, pending review and acknowledgment across separate CLI processes
      using an isolated database and updated catalog.
- [x] Resolve review findings and record acceptance evidence.
- [x] Update progress and retain the reviewed change for commit preparation.
- [x] Create the validated ticket commit at the user's request.

A valid missing-route response is now saved before `[]` is printed. Resolution
and acknowledgment remain separate, as verified by the lifecycle tests.

### Container-volume acceptance

The orchestrator ran 15 separate application containers against a newly created
isolated volume and an editable catalog mount, with networking disabled. Verified
all three saved criteria, route availability before pending review, deduplication,
idempotent acknowledgment, recovery across containers, invalid-catalog/ID errors
without record loss, and acknowledgment without reading an invalid catalog. A
separate container confirmed SQLite integrity and three stored requests. The test
volume was removed; the development volume was not modified.

## Verification and Review Record

Add a compact row when actual ticket work starts; do not prefill successful results.

| Ticket / criterion IDs | Tests, including real CLI cases | Docker command | Exit code and expected vs. observed console result | Reviewer verdict / remaining work |
|---|---|---|---|---|
| REQ-01 / PLS-0001-AC-01–04 (RED) | Real-CLI cases before direct routing | `docker run --rm --network none -v "$PWD/coverage:/app/coverage" shypple-routing:dev bundle exec ruby bin/test` | Exit 1; 20 tests, 44 assertions, 20 expected failures, 0 errors | Expected behavioral RED against the scaffold; superseded by verified GREEN |
| REQ-01 / PLS-0001-AC-01–04 (GREEN) | `test/acceptance/pls_0001_test.rb` real CLI subprocess cases, plus unit specs | Same Docker suite command; original-fixture console smoke | Exit 0; 49 runs (20 CLI), 350 assertions, no failures/errors/skips; 246/246 covered lines (100.00%); smoke returns `ABCD`, `589.30 USD` | Accepted independently; runtime verified and README drift fixed/rechecked |
| REQ-02 / WRT-0002-AC-01–04 (RED) | Eight additional real-CLI cases | Same Docker suite command | Exit 1; 28 tests, 265 assertions, eight expected failures, zero errors | New cheapest-route behavior absent; prior cases stayed green |
| REQ-02 / WRT-0002-AC-01–04 (GREEN) | `test/acceptance/wrt_0002_test.rb`, including 3+ legs, dates, exact sums, ties and cyclic input | Same Docker suite command; original-fixture cheapest smoke | Exit 0; 60 runs (28 CLI), 385 assertions, no failures/errors/skips; 265/265 covered lines (100.00%); `ERXQ → ETRG` | Accepted independently; current image matched source and tests |
| REQ-03 / TST-0003-AC-01–03 (RED) | Nine added real-CLI fastest cases | Same Docker suite command | Exit 1; 37 tests, 298 assertions, nine expected failures, zero errors | Prior 28 cases remained green; expected RED before fastest implementation |
| REQ-03 / TST-0003-AC-01–03 (GREEN) | Nine fastest CLI cases in `test/acceptance/tst_0003_test.rb`, including waits and prefix dominance | Same Docker suite command; original-fixture fastest smoke | Exit 0; 70 runs (37 CLI), 421 assertions, zero failures/errors/skips; 270/270 lines covered (100.00%); `QRST`, 17 days | Accepted independently; current image and full elapsed-time behavior verified |
| REQ-04 / SLD-0004-AC-01–06 (RED) | Eleven pending/ack/persistence CLI cases | Same Docker suite command | Exit 1; 48 tests, 389 assertions, 11 expected failures, zero errors; prior 37 passed | Missing persistence and administrative modes, not an environment failure |
| REQ-04 / SLD-0004-AC-01–06 (GREEN) | `test/acceptance/sld_0004_test.rb`: eleven persisted pending/ack CLI cases; real SQLite trigger aborts second row in a batch | Same Docker suite command; isolated admin smoke | Exit 0; 90 runs (45 CLI after the simplification below), 645 assertions, zero failures/errors/skips; 380/380 lines covered (100.00%) | Accepted independently; 15 application containers verified shared-volume lifecycle and SQLite integrity |

Record expected red failures separately from unexpected failures. Build or coverage
results alone do not prove functional acceptance. If a check is not run, say why.
Record blocking findings and their resolution here, without a separate report file.

Structure refactor: after the tickets were accepted, the code was split into
single-purpose objects (ADR-007) and each ticket's real-CLI cases moved to
`test/acceptance/` in `describe`/`it` (ADR-006), with unit specs added. The real-CLI
cases were the unchanged behavior contract during that refactor. RED rows keep the
original test-first counts; GREEN rows report the suite at each ticket's commit,
where runs include unit specs and the CLI case count is in parentheses.

Console checks are automated Minitest integration tests executed by `bin/test`,
not calls to internal methods alone. Follow AGENTS.md's Console Acceptance rules.
All four tickets have scoped CLI acceptance evidence above. Initial scaffold
checks are historical setup evidence, not substitutes for those acceptance cases.

## Delivery

- [x] All four tickets reviewed and accepted with criterion-to-test evidence.
- [x] Full test suite executed in Docker; current suite: 90 runs (45 CLI acceptance cases), 645 assertions, 380/380 lines covered (100.00%).
- [x] README commands and stdin/stdout behavior checked from the final checkout.
- [x] Source archive built and tested from an extracted copy; rebuild the ZIP from this commit before sending.

Delivery check: source was archived without Git metadata, databases or generated
reports, extracted into a new directory and built as `shypple-routing:delivery-check`.
Its offline full suite passed: 48 CLI tests, 555 assertions, no failures/errors/skips,
149/151 lines covered (98.67%). Docker layers were cached; this was not a
`--no-cache` build. This records the initial archive check, which predates the structure refactor.
Refactor check: a `git archive` ZIP of the refactored source was extracted, built as
`shypple-routing:delivery-check` (cached layers) and its offline suite passed: 90 runs,
645 assertions, no failures/errors/skips, 380/380 lines covered (100.00%). The
extracted image also returned the required `ABCD` JSON for the default stdin example.
Any ZIP prepared before the refactor is stale.

The optional `--explain` view is deferred. No background watcher, catalog versioning
or external notification delivery is planned. Do not send the ZIP or publish the
repository without user authorization.

Commit preparation check: the reviewed cumulative source for this phase was rebuilt
and its complete real-CLI Minitest suite passed in Docker before committing.

## Test Suite Simplification

At the user's request, overlapping tests were combined and equivalent invalid-input
variants were reduced to representative cases. The default-fixture direct test
already excludes a cheaper complete indirect route; mixed-case currency preservation
now shares the conversion case; the three-leg fastest case also verifies that price
does not control selection. Retained separate checks for exact monetary ordering,
connection chronology, deterministic ties, persistence and transactional rollback.

Verification (pre-refactor): rebuilt `shypple-routing:dev`, then ran the full offline Docker command
above: exit 0, 45 real-CLI tests, 509 assertions, no failures/errors/skips and 149/151
covered lines (98.67%). Earlier ticket counts remain historical evidence.
Independent review: accepted; no blocking regression gaps found.

The branch contains the seven planned commits. Final test simplification and
README refinements are included in the REQ-04 delivery commit; no separate
maintenance commit is retained. The first three commits are unchanged; the four
ticket commits were rewritten by the structure refactor with the same scope and messages.

README execution check: Compose build, all three sample criteria, mounted-feed
search/review and acknowledgment passed using an isolated volume. After the structure
refactor, the documented Docker test command passed with 90 runs and 645 assertions;
coverage HTML was generated (100.00%). Recorded CLI outputs for the three criteria,
input errors, feed errors and the pending/ack flows (26 cases) matched the
pre-refactor outputs byte for byte. README links were checked.
