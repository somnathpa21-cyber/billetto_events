# Billetto Events

A Ruby on Rails application that imports events from the Billetto API and allows authenticated users to like or dislike events.

The application uses Rails Event Store to record voting activity and maintains a dedicated read model to efficiently display vote counts and each user's current vote.

## Features

- Fetch and import events from the Billetto API.
- Handle cursor-based API pagination.
- Create and update events without duplicating existing records.
- Display upcoming events with title, date, image, description, and Billetto link.
- Authenticate users using Clerk.
- Allow authenticated users to like or dislike events.
- Allow users to switch between like and dislike.
- Prevent duplicate voting events when users repeat the same vote.
- Record voting activity as domain events using Rails Event Store.
- Maintain vote counts and each user's current vote through a dedicated read model.
- Process Billetto imports asynchronously using Sidekiq.
- Retry failed background jobs for configured Billetto API and pagination errors.
- Protect concurrent voting operations using database row-level locking.
- Automated unit, request, integration, job, and browser tests.

## Technology Stack

- Ruby 3.4.7
- Ruby on Rails 8.1.4
- PostgreSQL
- Redis
- Sidekiq
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

Redis is required by Sidekiq for background job storage and processing.

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
- Returning import statistics.

The job uses Active Job's `retry_on` mechanism