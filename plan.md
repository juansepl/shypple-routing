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
| REQ-01 | PLS-0001: cheapest direct route | Base and reviewed active specification | pending |
| REQ-02 | WRT-0002: cheapest direct or indirect route | REQ-01 | pending |
| REQ-03 | TST-0003: fastest direct or indirect route | REQ-02 | pending |
| REQ-04 | SLD-0004: saved searches and manual pending review | All three criteria | pending |
| Delivery | Full acceptance, usage documentation and ZIP | All four tickets | pending |

States: `pending`, `in_progress`, `needs_review`, `changes_requested`, `accepted`,
`blocked`. Apply the transition rules in AGENTS.md. A specification draft is not
an implemented feature; a test run with zero cases is not ticket acceptance.

## Commit Sequence

The planned initial sequence has **seven commits**: one base, one AI workflow,
one specification/plan and four functional requirements. The base and workflow
commits are recorded below; this document belongs to the specification/plan commit.
The four functional commits remain pending.

| Order | Message / scope | Commit status |
|---|---|---|
| 1 | Project bootstrap: Ruby, Docker, SQLite and test framework | Committed as `38965f2`; preserve the existing commit |
| 2 | `chore: configure AI-assisted development workflow` — AGENTS.md, role instructions and SDD rules | Committed as `d2324db` |
| 3 | `docs: define requirements and implementation plan` — docs/spec.md, plan.md and their README links | Included in this commit |
| 4 | `feat: implement REQ-01 with automated tests` — code, tests and progress | Pending implementation |
| 5 | `feat: implement REQ-02 with automated tests` — code, tests and progress | Pending implementation |
| 6 | `feat: implement REQ-03 with automated tests` — code, tests and progress | Pending implementation |
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

- [ ] Specify active criteria and map test scenarios.
- [ ] Settle relevant proposed behavior before affected tests are written.
- [ ] Write Minitest cases and confirm expected failures.
- [ ] Implement the ticket and verify affected tests plus the existing suite.
- [ ] Run real CLI acceptance cases for success, no route and invalid input.
- [ ] Reviewer accepts the scoped change, or findings are corrected and rechecked.
- [ ] Update progress and prepare the ticket commit when requested.

## Phase 2 — WRT-0002

- [ ] Refine its criteria and connection scenarios.
- [ ] Write tests and confirm expected failures.
- [ ] Implement and verify the ticket and existing behavior.
- [ ] Run real CLI cases asserting the selected multi-leg route and process contract.
- [ ] Resolve review findings and record acceptance evidence.
- [ ] Update progress and prepare the ticket commit when requested.

## Phase 3 — TST-0003

- [ ] Refine its criteria and elapsed-time scenarios.
- [ ] Write tests and confirm expected failures.
- [ ] Implement and verify the ticket and existing behavior.
- [ ] Run real CLI cases asserting elapsed-time selection and the process contract.
- [ ] Resolve review findings and record acceptance evidence.
- [ ] Update progress and prepare the ticket commit when requested.

## Phase 4 — SLD-0004

- [ ] Finalize the administrative interface and persistence behavior in the spec.
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
| — | — | — | No functional ticket execution yet | — |

Record expected red failures separately from unexpected failures. Build or coverage
results alone do not prove functional acceptance. If a check is not run, say why.
Record blocking findings and their resolution here, without a separate report file.

Console checks are automated Minitest integration tests executed by `bin/test`,
not calls to internal methods alone. Follow AGENTS.md's Console Acceptance rules.
The application is still a scaffold: all route and pending-review acceptance checks
remain pending. The previously recorded startup check is not route acceptance.

## Delivery

- [ ] All four tickets reviewed and accepted with criterion-to-test evidence.
- [ ] Full test suite executed in Docker; coverage gaps understood.
- [ ] README commands and stdin/stdout behavior checked from the final checkout.
- [ ] ZIP contents and build from the extracted ZIP verified.

The optional `--explain` view is deferred. No background watcher, catalog versioning
or external notification delivery is planned. Do not send the ZIP or publish the
repository without user authorization.
