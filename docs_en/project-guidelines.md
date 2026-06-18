# QuickPresence Rules and Lessons Learned

This document is the central source for QuickPresence architecture decisions, engineering rules, and operational lessons. It should be updated whenever an important decision changes or when a problem produces reusable knowledge.

In case of conflict:

1. security and data integrity come first;
2. behavior covered by tests represents the current contract;
3. this document guides new implementation work;
4. the product scope is documented in `docs_en/quick_presence_escopo_cs50.md`;
5. public maintenance notes are documented in `docs_en/production-maintenance.md`.

## 1. Project Goals

QuickPresence should remain a simple application for creating temporary attendance lists, sharing forms through links or QR Codes, receiving responses, and exporting data.

Product principles:

- participants do not need accounts;
- only the owner can access and manage their lists;
- each list accepts at most five custom fields;
- dates are stored in UTC and displayed in the list's time zone;
- responses expire according to the product retention policy;
- public links use hard-to-guess tokens;
- the main workflow should work well on mobile devices;
- operational simplicity is preferred over premature scalability.

## 2. Current Architecture

Main stack:

- Ruby on Rails full-stack;
- ERB, Turbo, and Stimulus;
- Bootstrap and Tailwind CSS;
- Devise for authentication;
- SQLite for the primary database, cache, queue, and Action Cable;
- Solid Cache and Solid Queue;
- local Active Storage;
- Caddy as reverse proxy and TLS terminator;
- Docker Compose for production execution.

Layer responsibilities:

- `controllers`: receive requests, authorize access, coordinate operations, and choose responses;
- `models`: represent data, relationships, validations, and entity-level rules;
- `services`: execute cohesive operations or transformations such as exports, PDF generation, and response cleanup;
- `jobs`: schedule and start asynchronous work while delegating complex logic;
- `views` and `helpers`: present data without concentrating business rules;
- `app/javascript/controllers`: progressive interface behavior;
- `config/locales`: all user-facing text;
- `docs` and `docs_en`: versioned decisions, rules, scope, operations, and lessons.

## 3. SOLID

Every new architecture decision and relevant change should consider SOLID principles. They guide decisions but do not justify unnecessary abstractions. A simple and clear solution is better than a class hierarchy created only to look flexible.

### 3.1 Single Responsibility

Each class or module should have one primary reason to change.

- controllers should not generate CSV, XLSX, PDF, or QR Codes directly;
- jobs should not duplicate rules already present in services or models;
- services should represent cohesive operations;
- helpers should not query or modify the database;
- models should not know HTTP or rendering details.

When a class accumulates validation, persistence, formatting, and integration concerns, split responsibilities only where a clear boundary exists.

### 3.2 Open/Closed

New behavior should be added without spreading conditionals across many layers.

- export formats should share a common representation of the data;
- new storage services should use the Active Storage interface;
- new languages should be added through locale files;
- new delivery behavior should respect Rails interfaces.

Do not create plugin systems or registries before there is a real second implementation.

### 3.3 Liskov Substitution

Implementations that respect the same contract should be replaceable without surprises.

- subclasses and adapters must preserve expected inputs, outputs, and errors;
- test doubles should reproduce the contract used by the code;
- an implementation should not require stricter preconditions than the abstraction it replaces.

Prefer composition and small objects over inheritance when that is clearer.

### 3.4 Interface Segregation

Objects should not depend on methods they do not use.

- pass only necessary data or objects to services;
- avoid generic objects that know the entire application;
- prefer small explicit APIs such as `call`, `render`, or `to_csv` when they describe the operation;
- do not use broad concerns to share unrelated responsibilities.

### 3.5 Dependency Inversion

Business rules should not be tied to replaceable external details when an abstraction brings real value.

- use Rails APIs for storage, jobs, email, and time;
- inject clocks, renderers, or gateways when this makes a rule testable or supports real alternative implementations;
- avoid calling external services directly from controllers or models;
- do not create artificial interfaces for stable and trivial dependencies.

## 4. Implementation Rules

- follow existing Rails conventions before creating custom structure;
- keep changes small and related to the requirement;
- avoid meaningful duplication, but do not abstract superficial coincidence;
- use structured APIs for CSV, YAML, JSON, dates, and URLs;
- use English names in code, database, tests, commits, and public documentation;
- documents in `docs/` may be written in Portuguese, and documents in `docs_en/` should be written in English;
- add comments only when they explain a non-obvious decision;
- do not include dead code, secrets, real keys, or unsafe examples;
- production migrations are immutable history;
- destructive database changes require backup and rollback planning;
- new dependencies need justification, active maintenance, and acceptable image impact.

Before creating a new abstraction, confirm at least one benefit:

- it reduces observable complexity;
- it removes relevant duplication;
- it isolates an external integration;
- it establishes a contract with more than one implementation;
- it improves testability in a concrete way.

## 5. Controllers, Authorization, and Parameters

- every authenticated action must start from `current_user`;
- lists must be loaded through `current_user.attendance_lists`, never through a global lookup followed by comparison;
- public routes may only find lists by `public_token`;
- received parameters must pass through Strong Parameters;
- controllers should stay focused on HTTP flow;
- multi-step or multi-format operations should be delegated to services;
- messages and redirects should use I18n.

No change may allow a user to view, update, export, or delete another user's data.

## 6. Models and Data Integrity

- domain validations should exist in models even when the interface also validates;
- associations and cascading deletes must be deliberate;
- critical rules should be enforced by database constraints or indexes when possible;
- public tokens must be generated with a cryptographically secure source and have a unique index;
- timestamps submitted by participants are not trusted; `submitted_at` is set by the server;
- dates should be stored in UTC;
- the original list time zone should remain saved;
- repeated queries should avoid N+1 and load only necessary data;
- retention changes must preserve the 48-hour product rule unless the requirement explicitly changes.

## 7. Services and Jobs

A service is appropriate when there is a cohesive operation that does not naturally belong to a single model or controller.

Rules:

- name it by operation or result;
- expose a small API;
- receive dependencies through the initializer or main method;
- avoid global state;
- return predictable results or raise specific errors;
- do not hide important side effects;
- cover the main rule with unit tests.

Jobs should:

- be safe to repeat whenever possible;
- delegate main operations to models or services;
- process in batches when volume may grow;
- log failures without exposing personal data;
- not assume data still exists when they run.

## 8. Interface and Internationalization

- no user-visible text should be inserted directly into controllers, views, or JavaScript when I18n can be used;
- English is the default locale;
- `pt-BR` should keep key parity with English;
- new text requires updates to both catalogs;
- forms should keep labels, error messages, and states accessible;
- successful public submissions must redirect to a final confirmation page instead of rendering a blank form again;
- JavaScript should improve the experience without blocking the basic flow;
- public links and QR Codes must use absolute URLs derived from the correct host and protocol;
- the interface should prioritize small screens and clear actions.

## 9. Security and Privacy

- `.env`, `config/master.key`, and real credentials never go to Git;
- `.env_model` documents names and fake values only;
- sensitive parameters must be filtered from logs;
- production must use HTTPS and secure cookies;
- `APP_DOMAIN` defines the allowed production host;
- only Caddy exposes public ports; Rails remains on the internal network;
- SQLite, consoles, debug endpoints, and administrative endpoints must not be exposed;
- the project must explain essential cookies and storage at `/privacy`;
- cookies, pixels, analytics, or non-essential storage must be disabled by default and loaded only after clear consent;
- the privacy notice may store only a local preference remembering that the user acknowledged it;
- never trust IDs, tokens, locale, time zone, or fields submitted by the client without validation;
- avoid logging attendance answers or other personal data;
- update gems and base images only after checking compatibility and tests;
- rotating `secret_key_base` invalidates cookies, sessions, and signed tokens;
- rotating `RAILS_MASTER_KEY` requires re-encrypting credentials and preserving the new key outside the repository.

## 10. Tests and Quality

Every bug fix should include a test that would fail before the fix when feasible.

Expected coverage:

- models: validations, associations, states, and time rules;
- controllers: authentication, authorization, responses, and formats;
- services: transformation, ordering, and operation effects;
- jobs: record selection and delegation;
- I18n: catalog parity;
- public flows: open, closed, future, expired, and invalid parameters.

Before integrating a change:

```bash
bin/rails test
```

In environments that block sockets used by parallel tests:

```bash
PARALLEL_WORKERS=1 bin/rails test
```

Run project-specific checks such as security analysis, linting, and asset validation when the changed area is affected.

## 11. Production, Containers, and Persistence

Required lessons:

- do not build the Rails image on a low-memory VM;
- build on a proper machine or CI and publish a versioned tag;
- confirm VM architecture before building (`amd64` or `arm64`);
- the validated production environment currently uses Oracle `VM.Standard.E2.1.Micro`, Ubuntu Minimal, and a `linux/amd64` image;
- the `VM.Standard.E2.1.Micro` should have swap configured, but swap is not enough for image builds;
- production domains should point to a reserved public IP, not an ephemeral address;
- operational files live in `~/quick_presence`, while persistent data remains in `/var/lib/quick_presence`;
- Docker Desktop on Windows needs WSL integration enabled;
- do not rely only on `latest`;
- the container is disposable, but data is not;
- SQLite and uploads live on the host under `/var/lib/quick_presence/storage`;
- Caddy data and certificates must persist outside containers;
- changing the image must not replace the storage directory;
- Caddy issues and renews certificates automatically after DNS and firewall are correct;
- ports `80` and `443` must be open in Oracle Cloud and the VM;
- only Caddy publishes ports to the internet;
- certificates should be tested by domain, not by IP address;
- DNS should have a single active `A` record for the root domain;
- `db:prepare` applies migrations on Rails container startup;
- image rollback does not roll back migrations;
- automatic VM maintenance should run after recurring application jobs, with logs, backup before restarting containers, and health checks after startup;
- backups must exist outside the VM.

Never run in production without understanding the impact:

```bash
docker compose down -v
docker volume prune
docker system prune --volumes
```

Complete operational deployment procedures are private local documentation and should not expose sensitive details in the public repository.

## 12. SQLite

SQLite fits the current scope because the application runs on a single VM with moderate load.

Rules:

- do not share the database file over a network filesystem across multiple servers;
- keep only one web instance writing to the database unless validated otherwise;
- preserve WAL-related files during operation and backup;
- make consistent backups with the app stopped or with a proper SQLite tool;
- monitor disk space;
- prepare the storage directory with permissions for UID/GID `1000`;
- consider PostgreSQL before using multiple VMs, high write concurrency, or high availability.

## 13. Git and Documentation

- the public documentation directories are versioned;
- documents must not contain secrets or unnecessary private paths;
- relevant architecture decisions should update this file;
- deployment changes should update the corresponding safe notes;
- product changes should update the scope;
- obsolete documentation should be fixed or removed;
- examples should use fake values;
- generated files, databases, uploads, and secrets remain ignored.

When reviewing a change, verify:

1. behavior is tested;
2. SOLID principles were considered without excessive abstraction;
3. authorization and data integrity were preserved;
4. new text is internationalized;
5. secrets were not included;
6. migrations and deploy have a safe path;
7. relevant documentation was updated.

## 14. Process for New Decisions

Before implementing an architecture change:

1. record the concrete problem;
2. identify which layers are responsible;
3. evaluate the simplest SOLID-compatible solution;
4. consider security, data, deploy, and rollback;
5. implement with tests proportional to the risk;
6. update this document when a reusable rule emerges.

SOLID does not mean creating many classes. For QuickPresence, good architecture means clear responsibilities, controlled dependencies, rules protected by tests, and operations that remain understandable on a small VM.
