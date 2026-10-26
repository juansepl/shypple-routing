# Technical Challenge

Ruby CLI to find the cheapest or fastest shipping route and save searches that
can be fulfilled when new sailings arrive.

**Implemented:** Docker, persistent SQLite, Minitest and coverage configuration.
The four functional tickets are still pending.

## 1. Tech Stack

- Ruby 4.0.9 and Bundler 4.0.20.
- SQLite (`sqlite3` 2.10.1) in a Docker volume.
- Docker / optional Docker Compose.
- Minitest 6.0.6 and SimpleCov 1.3.2.

## 2. Getting Started

Requires Docker. From the project root, with Docker Compose:

```bash
docker volume create shypple-routing-data
docker compose build
docker compose run --rm app
```

Or with Docker only:

```bash
docker build -t shypple-routing:dev .
docker run --rm -i -v shypple-routing-data:/app/data shypple-routing:dev
```

The base creates `/app/data/shypple.sqlite3` and exits. No migrations are needed
yet. The named volume keeps the database between runs. Building downloads dependencies.

See the [challenge](docs/CHALLENGE.md) and [sample catalog](fixtures/response.json).

## 3. Running Tests

After building:

```bash
docker compose run --rm -v ./coverage:/app/coverage app bundle exec ruby bin/test
```

Without Compose:

```bash
docker run --rm -v "$PWD/coverage:/app/coverage" shypple-routing:dev bundle exec ruby bin/test
```

Tests belong in `test/**/*_test.rb`. SimpleCov prints line coverage and generates
`coverage/index.html`, including untested application files. There are currently
**zero tests and 0.00% coverage**. Each ticket will add its tests.

## 4. Technical Decisions

- Plain Ruby CLI for the required stdin/stdout interface.
- SQLite in a persistent volume, without a database server.
- Pinned image and locked dependencies for reproducibility.

See [Architecture Decisions](docs/ARCHITECTURE-DECISIONS.md).

## 5. AI-Assisted Development

AI assisted with requirement analysis, design and project setup. Build, startup,
SQLite persistence and coverage generation were checked in Docker.

Workflow: acceptance criteria → tests and implementation → review → validation → commit.
Each ticket includes its code, tests and relevant documentation.

## 6. Limitations

- Route selection, pending searches and notifications are not implemented yet.
- Checks ran on ARM64; AMD64 execution is unverified.
- Background notifications, catalog versioning and a web interface are out of scope.
- Optional `--explain` output is deferred until the required tickets are complete.
