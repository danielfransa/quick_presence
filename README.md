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
- export attendance data as CSV.

Participants can open the public link or scan the QR code, fill in the fields configured by the organizer, and submit their attendance while the list is open.

## Project Status

This repository is at the beginning of development. The first milestone is a Rails MVP focused on the core attendance workflow.

Planned MVP features:

- user registration and authentication;
- attendance list CRUD;
- custom attendance fields;
- public attendance form by token;
- QR code generation;
- validity control by date and time;
- response storage with timestamps;
- CSV export.

## Tech Stack

- Ruby on Rails
- SQLite
- ERB
- Turbo
- Stimulus
- Devise
- rqrcode
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

## Open Source License

QuickPresence is released under the MIT License.

MIT was chosen because it is a short, permissive open source license that allows people to use, copy, modify, merge, publish, distribute, sublicense, and sell copies of the software, as long as the copyright and license notice are preserved.

For this project, MIT is a good fit because the goal is educational, collaborative, and friendly to broad adoption. If the project later needs explicit patent language, Apache License 2.0 would be the closest permissive alternative to reconsider.

See [LICENSE](LICENSE) for details.
