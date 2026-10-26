FROM ruby:4.0.9-slim-bookworm@sha256:16af53d3b3909a6ec074ca7e208aac3b912b04b3da80764e7fda9b9640f68696 AS build

ENV BUNDLE_FROZEN=true \
    BUNDLE_FORCE_RUBY_PLATFORM=true

RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle install

FROM ruby:4.0.9-slim-bookworm@sha256:16af53d3b3909a6ec074ca7e208aac3b912b04b3da80764e7fda9b9640f68696

ENV BUNDLE_FROZEN=true \
    DATABASE_PATH=/app/data/shypple.sqlite3

WORKDIR /app
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY Gemfile Gemfile.lock ./
COPY bin/ bin/
COPY lib/ lib/
COPY test/ test/
COPY fixtures/ fixtures/

CMD ["bundle", "exec", "ruby", "bin/app"]
