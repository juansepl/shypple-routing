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
| REQ-04 | SLD-0004: saved searches and manual pending review | All three criteria | in_progress |
| Delivery | Full acceptance, usage documentation and ZIP | All four tickets | pending |

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
| 6 | `feat: implement REQ-03 with automated tests` — code, tests and progress | Included in this commit; Docker suite and independent review passed |
| 7 | `feat: implement REQ-04 with automated tests` — code, tests and progress | Pending implementation |

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

The independent Reviewer accepted this documentation scope with no blocking
findings. Local links, requirement aliases, 17 acceptance criteria and 29 scenario
mappings were checked, along with `git diff --check`. No functional tests were
run for this documentation-only change. Ticket-specific open proposals still
require refinement before the affected implementation starts. Accepted setup
does not establish functional implementation. Commit delivery is tracked separately
in the Commit Sequence table.

A follow-up independent review accepted the explicit seven-commit sequence and
real-console acceptance rules. CLI checks remain pending for each functional ticket.

## Phase 1 — PLS-0001

Active stage: **SPECIFY → WRITE TESTS → IMPLEMENT**. The user authorized the
remaining implementation, verification and review phases, prioritizing the least
code needed to satisfy the requirements. Resolve working policies in the spec,
then proceed sequentially through the four tickets. No new commits are authorized.

- [x] Specify active criteria and map test scenarios (analysis draft).
- [x] Settle relevant proposed behavior before affected tests are written.
- [x] Write Minitest cases and confirm expected failures.
- [x] Implement the ticket and verify affected tests plus the existing suite.
- [x] Run real CLI acceptance cases for success, no route and invalid input.
- [x] Reviewer accepts the scoped change, or findings are corrected and rechecked.
- [ ] Update progress and prepare the ticket commit when requested.

Earlier analysis draft: Requirements Analyst retained the four REQ-01 acceptance IDs and
expanded its scenarios from 8 to 16. New decision groups REQ-01-D-01 through D-04
cover exact price ordering, genuine ties, stdin boundaries and feed/error policy;
they remain proposed for user review. The existing higher-value rule for unequal
quotes of the same sailing is unchanged and precedes comparison between routes.
Read-only sample calculations still select `ABCD` (about EUR 523.357016).
No project tests were added or run; no production code or commits were created.
The user confirmed a general conservative-business-risk principle for unspecified
product decisions. Apply it to proposed behavior without inventing pricing data
or changing the requested search criterion. D-01 through D-04 were selected as working policies under the later authorization
to complete the solution; the exact policies are in docs/spec.md.

## Phase 2 — WRT-0002

Active stage: **WRITE TESTS → IMPLEMENT**. Exact rational sums, same-day
connections and deterministic route ties are selected in docs/spec.md.

- [x] Refine its criteria and connection scenarios.
- [x] Write tests and confirm expected failures.
- [x] Implement and verify the ticket and existing behavior.
- [x] Run real CLI cases asserting the selected multi-leg route and process contract.
- [x] Resolve review findings and record acceptance evidence.
- [ ] Update progress and prepare the ticket commit when requested.

Additional checks: the reviewer independently matched an exhaustive oracle on
200 deterministic generated catalogs; the orchestrator also matched 16 generated
catalogs through actual Docker CLI processes (seed 814). No routing defects found.

## Phase 3 — TST-0003

Active stage: **WRITE TESTS → IMPLEMENT**. Use elapsed journey time including
waits; direct and indirect routes participate regardless of price.

- [x] Refine its criteria and elapsed-time scenarios.
- [x] Write tests and confirm expected failures.
- [x] Implement and verify the ticket and existing behavior.
- [x] Run real CLI cases asserting elapsed-time selection and the process contract.
- [x] Resolve review findings and record acceptance evidence.
- [ ] Update progress and prepare the ticket commit when requested.

Independent reviewer accepted the phase and matched an exhaustive fastest-route
oracle across 200 deterministic generated catalogs. Persistence is not part of
this acceptance.

## Phase 4 — SLD-0004

Active stage: **WRITE TESTS → IMPLEMENT**. Use the selected `--pending`,
`--ack ID` and `--feed PATH` contract and one-table SQLite state model.

- [x] Finalize the administrative interface and persistence behavior in the spec.
- [ ] Write state-transition and cross-execution scenarios and tests.
- [ ] Confirm expected failures, then implement using isolated test databases.
- [ ] Verify the full suite and repeated manual-review behavior.
- [ ] Exercise search, pending review and acknowledgment across separate CLI processes
      using an isolated database and updated catalog.
- [ ] Resolve review findings and record acceptance evidence.
- [ ] Update progress and prepare the ticket commit when requested.

Until this ticket is implemented, returning `[]` does not fulfill saved searches.
Keep search resolution separate from notification acknowledgment.

## Verification and Review Record

Add a compact row when actual ticket work starts; do not prefill successful results.

| Ticket / criterion IDs | Tests, including real CLI cases | Docker command | Exit code and expected vs. observed console result | Reviewer verdict / remaining work |
|---|---|---|---|---|
| REQ-01 / PLS-0001-AC-01–04 (RED) | Real-CLI cases before direct routing | `docker run --rm --network none -v "$PWD/coverage:/app/coverage" shypple-routing:dev bundle exec ruby bin/test` | Exit 1; 20 tests, 44 assertions, 20 expected failures, 0 errors | Behavioral RED against the scaffold, after dependencies were available; implementation in progress |
| REQ-01 / PLS-0001-AC-01–04 (GREEN) | `test/acceptance/pls_0001_test.rb` real CLI subprocess cases, plus unit specs | Same Docker suite command; original-fixture console smoke | Exit 0; 49 runs (20 CLI), 350 assertions, no failures/errors/skips; 246/246 covered lines (100.00%); smoke returns `ABCD`, `589.30 USD` | Accepted independently; runtime verified and README drift fixed/rechecked |
| REQ-02 / WRT-0002-AC-01–04 (RED) | Eight additional real-CLI cases | Same Docker suite command | Exit 1; 28 tests, 265 assertions, eight expected failures, zero errors | New cheapest-route behavior absent; prior cases stayed green |
| REQ-02 / WRT-0002-AC-01–04 (GREEN) | `test/acceptance/wrt_0002_test.rb`, including 3+ legs, dates, exact sums, ties and cyclic input | Same Docker suite command; original-fixture cheapest smoke | Exit 0; 60 runs (28 CLI), 385 assertions, no failures/errors/skips; 265/265 covered lines (100.00%); `ERXQ → ETRG` | Accepted independently; current image matched source and tests |
| REQ-03 / TST-0003-AC-01–03 (RED) | Nine added real-CLI fastest cases | Same Docker suite command | Exit 1; 37 tests, 298 assertions, nine expected failures, zero errors | Prior 28 cases remained green; fastest implementation in progress |
| REQ-03 / TST-0003-AC-01–03 (GREEN) | Nine fastest CLI cases in `test/acceptance/tst_0003_test.rb`, including waits and prefix dominance | Same Docker suite command; original-fixture fastest smoke | Exit 0; 70 runs (37 CLI), 421 assertions, zero failures/errors/skips; 270/270 lines covered (100.00%); `QRST`, 17 days | Accepted independently; current image and full elapsed-time behavior verified |

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
Route acceptance for the implemented tickets is recorded above; later tickets add
their rows when implemented. The startup check is not route acceptance.

## Delivery

- [ ] All four tickets reviewed and accepted with criterion-to-test evidence.
- [ ] Full test suite executed in Docker; coverage gaps understood.
- [ ] README commands and stdin/stdout behavior checked from the final checkout.
- [ ] ZIP contents and build from the extracted ZIP verified.

The optional `--explain` view is deferred. No background watcher, catalog versioning
or external notification delivery is planned. Do not send the ZIP or publish the
repository without user authorization.

Commit preparation check: the reviewed cumulative source for this phase was rebuilt
and its complete real-CLI Minitest suite passed in Docker before committing.
