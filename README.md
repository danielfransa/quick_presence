# QuickPresence

QuickPresence is an open source web application for creating temporary attendance lists with custom fields, public share links, QR codes, validity windows, response tracking, and CSV export.

The project is designed for classes, talks, workshops, meetings, training sessions, and small events where an organizer needs to collect attendance quickly without requiring participants to create an account.

## Purpose

QuickPresence helps an authenticated organizer:

- create attendance lists;
- define up to five custom text fields per list;
- set start and end times for submissions;
- generate a public attendance form link;
- generate a QR code for fast access;
- review submitted responses;
- export attendance data as CSV;
- automatically delete submitted responses 48 hours after the list's end time.

Participants can open the public link or scan the QR code, fill in the fields configured by the organizer, and submit their attendance while the list is open.

Submitted responses are retained for download for 48 hours after the attendance list's end time. After that window, responses and answers are automatically deleted from the system.

Organizer accounts use usernames instead of email addresses. Password recovery and password changes are not available in this version, so organizers should choose a strong password and store it safely.

## Project Status

This repository is at the beginning of development. The first milestone is a Rails MVP focused on the core attendance workflow.

Planned MVP features:

- username-only user registration and authentication;
- attendance list CRUD;
- custom attendance fields;
- public attendance form by token;
- QR code generation;
- validity control by date and time;
- response storage with timestamps;
- CSV export;
- automatic response deletion after the 48-hour download window.

## Tech Stack

- Ruby on Rails
- SQLite
- ERB
- Turbo
- Stimulus
- Devise
- rqrcode
- Prawn
- Tailwind CSS
- Bootstrap
- csv
- I18n

## Internationalization

All project-facing text should be written in English by default. User-facing text in the application should be prepared for translation through Rails I18n.

Portuguese and other languages should be added through locale files instead of hard-coded strings.

## Development

Install dependencies:

```bash
bundle install
```

Prepare the database:

```bash
bin/rails db:prepare
```

Run the application:

```bash
bin/dev
```

Run tests:

```bash
bin/rails test
```

## Production With Docker

The production stack uses a prebuilt Rails image, persistent SQLite storage,
and Caddy for automatic HTTPS. The image is built on the development machine
and pulled by the small Oracle VM; production does not build Rails locally.
Create the local environment file:

```bash
cp .env_model .env
```

The real `.env` is ignored by Git and must never be committed. Prepare the
persistent host directory once:

```bash
sudo bin/prepare-production-storage
```

Then start the application:

```bash
docker compose -f compose.production.yml pull
docker compose -f compose.production.yml up -d
```

The validated server setup uses Oracle `VM.Standard.E2.1.Micro` with Ubuntu
Minimal, `linux/amd64`, 2 GB of swap, and deployment files in
`~/quick_presence`.
SQLite databases and Active Storage uploads are stored in
`/var/lib/quick_presence/storage` by default. This path is mounted at
`/rails/storage` inside the container and is not replaced when the image or
container changes. Caddy certificates are also persisted outside its container.

To deploy a new version, update `APP_IMAGE` in `.env` and run the two Docker
Compose commands again. Back up the host storage directory regularly, using a
filesystem snapshot or stopping the application while copying it.

See [the Oracle production deployment guide](docs/production-oracle-deploy.md)
for DNS, firewall, image architecture, HTTPS, updates, rollback, and backups.

Project architecture, engineering rules, and accumulated lessons are documented
in [the project guidelines](docs/project-guidelines.md).

## Open Source License

QuickPresence is released under the MIT License.

MIT was chosen because it is a short, permissive open source license that allows people to use, copy, modify, merge, publish, distribute, sublicense, and sell copies of the software, as long as the copyright and license notice are preserved.

For this project, MIT is a good fit because the goal is educational, collaborative, and friendly to broad adoption. If the project later needs explicit patent language, Apache License 2.0 would be the closest permissive alternative to reconsider.

See [LICENSE](LICENSE) for details.
