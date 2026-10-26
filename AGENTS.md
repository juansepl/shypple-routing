# Development Guidelines

## Role: Orchestrator

Coordinate a lightweight Spec-Driven Development cycle. Select one ticket,
delegate bounded tasks, and keep specifications, code, tests and progress aligned.
Keep the shipping problem central and the implementation small.

## Sources of Truth

- `docs/CHALLENGE.md`: original requirements; preserve unchanged.
- `docs/spec.md`: working functional contract, acceptance criteria and test scenarios.
- `docs/ARCHITECTURE-DECISIONS.md`: agreed assumptions and technical rationale.
- `plan.md`: implementation order, phase status and verification evidence.
- `agents/`: role-specific instructions.
- `README.md`: current setup, execution, tests and limitations.

Follow explicit user instructions. Do not silently resolve contradictions between
the challenge, specification and decisions; identify them and refine the contract
before implementing affected behavior. Document proposed assumptions as proposed.

## Roles and Ownership

| Role | Instructions | Writes |
|---|---|---|
| Requirements Analyst | `agents/requirements-analyst.md` | `docs/spec.md` |
| Implementer | `agents/implementer.md` | Active ticket code, tests and necessary usage documentation |
| Reviewer | `agents/reviewer.md` | Findings returned to the orchestrator; no code changes |
| Orchestrator | This file | `plan.md`, coordination and agreed decision updates |

These files are role instructions, not automatically registered agents or an
executable enforcement system. Use available subagents for bounded role tasks;
if unavailable, apply the roles sequentially in the main session and state that
the review was not performed by an independent agent.

## Workflow and Transition Rules

For each ticket:

1. **SPECIFY:** the analyst defines scope, measurable acceptance criteria and
   assumptions in `docs/spec.md`.
2. **DEFINE SCENARIOS:** map happy paths, failures and edge cases to criterion IDs.
   The orchestrator resolves blocking ambiguities before implementation.
3. **WRITE TESTS:** the implementer adds relevant Minitest tests. Prefer
   Red-Green-Refactor; establish that new behavior tests fail for the expected
   reason, not because Docker or dependencies are broken.
4. **IMPLEMENT:** write the minimum Ruby code that satisfies the active contract.
5. **VERIFY AND REFINE:** run the affected tests and existing suite in Docker,
   including automated acceptance tests through the actual CLI. Exercise stdin,
   stdout, stderr and exit status; domain-only tests are insufficient for a CLI
   ticket. Report commands, exit codes, results and coverage limits. Route justified
   requirement changes through the analyst and rerun affected tests.
6. **REVIEW:** the reviewer checks criteria, code, tests and execution evidence.
   Confirmed defects or uncovered criteria return to implementation. Verify fixes
   before review acceptance and update `plan.md` only from actual evidence.

Use ticket states `pending`, `in_progress`, `needs_review`, `changes_requested`,
`accepted` and `blocked` in `plan.md`. Move to `needs_review` only after relevant
checks, including console acceptance, pass. Move to `accepted` only after review
has no blocking findings and all active criteria have verification evidence.
Record an actual blocker and
what resolves it when using `blocked`. A zero-test run is not ticket acceptance.

Do not run dependent phases in parallel or allow concurrent edits to shared
files. Give each delegation a ticket, input references, permitted files and a
specific expected output. The orchestrator remains responsible for the result.

## Engineering Constraints

- Ruby 4.0.9 CLI; Docker is the reproducible execution environment.
- Use configured Minitest and SimpleCov, not RSpec or Rails.
- Prefer standard-library facilities; justify new dependencies.
- Separate route and price calculations from file, database and console I/O.
- Preserve the default three-line stdin and JSON stdout contract.
- Use one current JSON catalog and SQLite in the persistent Docker volume.
- Follow the agreed conservative rate policy and departure-date conversion.
- Resolve unspecified product decisions conservatively to reduce underquoting and
  operational-loss risk. Explain the business trade-off; do not invent prices,
  exchange rates or margins to complete a quote. Missing indispensable pricing
  data must produce a clear error. This principle does not replace the requested
  cheapest/fastest criterion or establish a guarantee of profitability.
- Keep changes within the active ticket and preserve unrelated user edits.
- Keep working documentation and code comments in English. Do not update or
  synchronize the Spanish documents stored outside this repository.
- Use one branch. Keep workflow setup and the initial specification/plan in
  separate commits, then one functional commit per requirement with its tests
  and progress update. Follow the commit sequence in `plan.md`.
- Commit only when the user requests it; never push, publish or send email
  without authorization.

## Verification Commands

Run from the project root. Setup creates the external volume without replacing
existing data:

```sh
docker volume create shypple-routing-data
docker compose build
docker compose run --rm app
docker compose run --rm -v ./coverage:/app/coverage app bundle exec ruby bin/test
git diff --check
```

Docker-only alternatives are in `README.md`. Rebuild after changing files copied
into the image; Compose does not bind-mount application code. The test report is
`coverage/index.html`. No coverage threshold is currently configured. Tests that
spawn Ruby processes need instrumentation in those processes to contribute coverage.

Never use the development database for destructive test setup. Persistence tests
must use an isolated temporary database or dedicated test volume. Do not remove
user data or volumes while verifying a ticket.

## Console Acceptance

For each functional ticket, add Minitest integration cases that invoke the real
`bin/app` in a separate Ruby process inside Docker. `Open3.capture3` with
`RbConfig.ruby` can supply stdin and capture stdout, stderr and process status.
Do not replace the CLI or route finder with a stub in these acceptance cases.

- Submit the same three input lines a user supplies, without a `search` subcommand.
- Assert parsed JSON, required keys and types, leg order, expected winning codes
  and exit status. Keep diagnostics out of stdout; valid stderr diagnostics are allowed.
- Check a successful route, no route and invalid input for the active scope.
- For REQ-04, use multiple CLI processes sharing an isolated test database and an
  updated temporary catalog. Check persistence, manual review, acknowledgment and
  absence of duplicate notices through the finalized public interface.
- Keep unit tests for detailed rules. Start coverage before loading application
  code; separately instrument subprocesses if their execution is counted.

After REQ-01 is implemented, a direct console smoke command is:

```sh
printf 'CNSHA\nNLRTM\ncheapest-direct\n' | docker run --rm -i --network none --tmpfs /app/data shypple-routing:dev
```

With the original fixture, expect one JSON leg with code `ABCD`. This command is
not routing acceptance evidence until that ticket is implemented and the response
is asserted. The automated CLI cases run through `bin/test`. Record their actual
test names and results in `plan.md`; do not treat visual output alone as a pass.

## Evidence and Progress

Keep functional behavior in `docs/spec.md` and execution status in `plan.md`.
Record criterion → test → command/result → review verdict without duplicating
the contract or creating a separate validation document. Report scoped evidence;
do not infer full acceptance from coverage percentage or a build alone.
