# Billetto Events

A Ruby on Rails application that imports events from the Billetto API and allows authenticated users to like or dislike events. Voting activity is recorded using Rails Event Store, and vote totals are displayed on the events listing page.

## Features

- Fetch and import events from the Billetto API.
- Handle cursor-based API pagination.
- Create and update events without duplicating existing records.
- Display upcoming events with title, date, image, description, and Billetto link.
- Authenticate users using Clerk.
- Allow authenticated users to like or dislike events.
- Allow users to change their votes.
- Record voting activity as domain events using Rails Event Store.
- Maintain vote counts and each user's current vote.
- Process Billetto imports asynchronously using Sidekiq.
- Automatically synchronize Billetto events every hour using Sidekiq Cron.
- Prevent overlapping imports using a Redis-based distributed lock.
- Retry failed background jobs for configured Billetto API and pagination errors.
- Automated unit, request, integration, job, and browser tests.

## Technology Stack

- Ruby 3.4.7
- Ruby on Rails 8.1.4
- PostgreSQL
- Redis
- Sidekiq
- Sidekiq Cron
- Active Job
- RSpec
- Capybara and Selenium WebDriver
- Clerk authentication
- Rails Event Store
- RestClient

## Prerequisites

Make sure the following are installed:

- Ruby 3.4.7
- Bundler
- PostgreSQL
- Redis
- Google Chrome (for system/browser tests)

## Getting Started

### 1. Clone the repository

```bash
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd billetto_events
```

### 2. Install dependencies

```bash
bundle install
```

### 3. Configure credentials

The application uses Rails encrypted credentials to store API keys and secrets.

Edit credentials:

```bash
EDITOR=nano bin/rails credentials:edit
```

Configure the following structure:

```yaml
billetto:
  api_keypair: YOUR_BILLETTO_API_KEYPAIR

clerk:
  publishable_key: YOUR_CLERK_PUBLISHABLE_KEY
  secret_key: YOUR_CLERK_SECRET_KEY
```

Never commit actual API keys, secrets, or the `config/master.key` file.

For deployment or another environment, provide the Rails master key securely through `RAILS_MASTER_KEY`.

### 4. Set up the database

Make sure PostgreSQL is running, then execute:

```bash
bin/rails db:create
bin/rails db:migrate
```

### 5. Start Redis

Sidekiq uses Redis for background job storage and processing.

Start Redis:

```bash
sudo systemctl start redis-server
```

Verify the Redis connection:

```bash
redis-cli ping
```

Expected output:

```text
PONG
```

### 6. Import events from Billetto

The application supports both synchronous and asynchronous imports.

**Synchronous import**

```bash
bin/rails billetto:import_events
```

This runs the importer directly through the Rake task.

**Asynchronous import**

Start Sidekiq first (see the Background Processing section), then run:

```bash
bin/rails billetto:enqueue_import
```

This enqueues `BillettoImportJob` for background execution.

### 7. Start the Rails server

```bash
bin/rails server
```

Open:

```text
http://localhost:3000
```

## Background Processing

The application uses Active Job with Sidekiq as its queue adapter.

### Billetto import job

`BillettoImportJob` executes the Billetto importer in the background.

Responsibilities include:

- Fetching and importing events from Billetto.
- Logging import progress and results.
- Retrying configured Billetto API and pagination errors.
- Preventing simultaneous imports using a Redis lock.

### Starting Sidekiq

Start the Sidekiq worker in a separate terminal:

```bash
bundle exec sidekiq -q default
```

Keep this process running while background jobs need to be processed.

### Automatic hourly synchronization

Sidekiq Cron schedules Billetto synchronization automatically.

The schedule is configured in `config/schedule.yml`:

```yaml
billetto_import:
  cron: "0 * * * *"
  class: "BillettoImportJob"
  queue: default
  description: "Synchronize Billetto events every hour"
```

The job runs at the beginning of every hour.

The schedule is loaded when the Sidekiq server starts through:

```text
config/initializers/sidekiq.rb
```

**Important:** Sidekiq must remain running for scheduled jobs to be enqueued and processed.

### Preventing overlapping imports

A Redis-based lock is used to prevent multiple Billetto imports from executing simultaneously.

Implementation:

```text
app/lib/redis_lock.rb
```

The lock uses:

- Atomic Redis `SET NX EX` for acquisition.
- A unique token for each lock owner.
- A 30-minute expiration to prevent abandoned locks from remaining indefinitely.
- A Lua script to ensure only the lock owner can release the lock.

This protects the importer from overlapping scheduled or manually enqueued jobs.

## Authentication

Clerk handles user authentication.

The application provides:

- Sign-in page: `/sign-in`
- Sign-up page: `/sign-up`
- Authentication status endpoint: `/auth-status`

Users can browse events without signing in. Authentication is required to submit a like or dislike vote.

Configure the Clerk application and its allowed development domain in the Clerk dashboard.

## Voting Architecture

Voting uses a command and event-driven approach with Rails Event Store.

### Voting flow

1. An authenticated user submits a like or dislike.
2. The voting controller creates the corresponding command.
3. The command bus executes the command.
4. The command publishes a domain event to Rails Event Store.
5. The event is linked to the corresponding user stream.
6. A subscribed projector updates the `event_votes` read model.
7. The events page displays updated vote totals and the current user's vote.

### Domain events

- `Events::EventLiked`
- `Events::EventDisliked`

Each event contains:

- `event_id`
- `user_id`

Events are published to an event-specific stream and linked to a user-specific stream.

### Read model

The `event_votes` table provides a query-friendly representation of the latest vote for each user and event.

A unique database index on `event_id` and `user_id` prevents duplicate vote records. Switching between like and dislike updates the existing vote.

## Running Tests

Run the complete RSpec suite:

```bash
bundle exec rspec
```

Run individual test groups:

```bash
bundle exec rspec spec/models
bundle exec rspec spec/integrations
bundle exec rspec spec/domain
bundle exec rspec spec/lib
bundle exec rspec spec/jobs
bundle exec rspec spec/requests
bundle exec rspec spec/system
```

System tests use Capybara and headless Chrome.

The test environment uses a test-only Clerk middleware so browser tests do not require external Clerk authentication requests. Request specs cover authenticated and unauthenticated voting behavior.

## Project Structure

```text
app/
  controllers/
    application_controller.rb
    clerk_controller.rb
    events_controller.rb
    voting_controller.rb

  domain/
    events/
    voting/
    fact.rb

  integrations/
    billetto/
      client.rb
      importer.rb

  jobs/
    billetto_import_job.rb

  lib/
    redis_lock.rb

  models/
    event.rb
    event_vote.rb

  views/
    clerk/
    events/

config/
  initializers/
    application_subscriptions.rb
    clerk.rb
    command_bus.rb
    rails_event_store.rb
    sidekiq.rb

  schedule.yml

lib/
  command/
  application_subscriptions.rb
  event_store_injector.rb
  tasks/
    billetto.rake

spec/
  domain/
  integrations/
  jobs/
  lib/
  models/
  requests/
  system/
```

## Design Considerations

- **Separation of concerns:** Billetto API communication, importing, voting commands, and event projections are separated into dedicated components.
- **Idempotent importing:** Existing events are updated instead of duplicated.
- **Database constraints:** Unique indexes protect event identifiers and user-event votes.
- **Event-driven architecture:** Voting actions are represented as domain events.
- **Read model:** Vote totals are queried efficiently without replaying the event store for every page request.
- **Authentication:** Voting endpoints require a valid Clerk session.
- **Background processing:** Sidekiq handles potentially long-running Billetto imports asynchronously.
- **Scheduled synchronization:** Sidekiq Cron automatically schedules recurring imports.
- **Concurrency protection:** Redis locking prevents overlapping import executions.

## Future Improvements

- Add pagination and filtering for large event listings.
- Add monitoring and retry strategies for external API failures.
- Add dedicated performance and load tests.
- Improve event synchronization observability.
- Add a dashboard for monitoring background job execution and import history.

## License

This project was created as a technical assignment.