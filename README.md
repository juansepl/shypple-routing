# Technical Challenge

Ruby CLI to find shipping routes by price or duration and save searches without results.

## 1. Tech Stack

Ruby 4.0.9, SQLite, Docker Compose, Minitest and SimpleCov.

## 2. Getting Started

With Docker running, execute from the project root:

```bash
docker volume create shypple-routing-data
docker compose build
printf 'CNSHA\nNLRTM\ncheapest-direct\n' | docker compose run --rm -T app
```

Enter origin, destination and criterion on three lines: `cheapest-direct`,
`cheapest` or `fastest`. Returns a JSON route, or `[]` and saves the search.

Review pending searches and acknowledge a result (`1` is an ID from `available`):

```bash
docker compose run --rm -T app bundle exec ruby bin/app --pending
docker compose run --rm -T app bundle exec ruby bin/app --ack 1
```

To update the catalog, copy and edit the sample, then use it for searches and reviews:

```bash
cp fixtures/response.json fixtures/current.json
# Edit fixtures/current.json:
printf 'CNSHA\nNLRTM\ncheapest\n' | docker compose run --rm -T -v "$PWD/fixtures:/feeds:ro" app bundle exec ruby bin/app --feed /feeds/current.json
docker compose run --rm -T -v "$PWD/fixtures:/feeds:ro" app bundle exec ruby bin/app --feed /feeds/current.json --pending
```

## 3. Running Tests

Rebuild after changing code or tests:

```bash
docker compose build
docker compose run --rm -T -v ./coverage:/app/coverage app bundle exec ruby bin/test
```

Acceptance specs in `test/acceptance/` run the real CLI per ticket; unit specs in
`test/unit/` cover detailed rules. Coverage report: `coverage/index.html`. Tests use
isolated databases.

## 4. Technical Decisions

- Exact rational pricing.
- SQLite persistence for searches and notices.
- One route finder shared by all criteria.
- Single-purpose objects: feed parsers, criterion strategies, forms, services and an
  SQL repository (ADR-007).

See [Architecture Decisions](docs/ARCHITECTURE-DECISIONS.md).

## 5. AI-Assisted Development

AI assisted with specifications, tests, implementation and review.
See [workflow](AGENTS.md), [requirements](docs/spec.md) and [plan](plan.md).

## 6. Limitations

Manual catalog updates and pending review. Saved results reflect prices at review
time. ARM64 verified; AMD64 unverified. Keep the Docker volume to preserve data.
