# QuickPresence - CS50 Final Project Scope

## 1. Project Overview

QuickPresence is an open source web application for creating temporary attendance lists with custom fields, public links, QR Codes, and CSV export.

The main idea is to let a person or institution quickly create an attendance list for a class, lecture, event, meeting, workshop, or training session. After creating a list, the system generates a public link and a QR Code. Participants open the form, fill in the fields configured by the organizer, and submit their attendance. The organizer can then review responses and export the data.

The project is a Rails full-stack application using SQLite as the database and Devise for authentication.

## 2. Product Goal

The application should allow:

- user registration and login;
- attendance list creation;
- up to five custom fields per list;
- automatic public link generation;
- QR Code generation for fast access;
- public attendance submission without participant login;
- start and end time control;
- response review;
- CSV and XLSX export;
- automatic deletion of responses 48 hours after the list's end time;
- a final confirmation page after public submission.

## 3. Defined Stack

```txt
Ruby on Rails
SQLite
Devise
ERB
Turbo
Stimulus
Tailwind CSS
Bootstrap
rqrcode
Prawn
prawn-svg
csv
Foreman
Solid Queue
Solid Cache
```

The current recommendation is to use server-rendered Rails views instead of React or Angular. This keeps complexity low and allows a more complete CS50 final project.

Current project decisions:

- use Tailwind CSS through `tailwindcss-rails`;
- use Bootstrap for the main interface and page layout;
- use `bin/dev` with Foreman for local development;
- each list stores its own time zone;
- the browser detects the creator's time zone automatically;
- organizer accounts use usernames instead of email addresses;
- password recovery and password changes are not available in this version;
- code, database names, tests, and public documentation should use English;
- architecture, rules, scope, operation, and lessons are documented in `docs` and `docs_en`;
- `docs/project-guidelines.md` is the central engineering rules document.

## 4. User Types

### Organizer

An authenticated user who can:

- create attendance lists;
- edit owned lists;
- define custom fields;
- define the response window;
- generate a public link;
- view a QR Code;
- review responses;
- close a list manually;
- export responses.

### Participant

A public user without login who can:

- access the attendance form by link or QR Code;
- fill in the fields configured by the organizer;
- submit attendance while the list is open;
- see a final confirmation page after submission.

## 5. Main Flow

Example:

1. The teacher or organizer creates an account.
2. They sign in.
3. They create a list named `Database Class`.
4. They define a response window, such as `19:00` to `19:20`.
5. They define fields such as student ID, name, and class.
6. The system generates a public link, for example `/a/abc123`.
7. The system generates a QR Code for that link.
8. Students scan the QR Code and fill in the form.
9. The system records answers with a server-side timestamp.
10. The participant is redirected to a final confirmation page.
11. After the end time, the form stops accepting responses.
12. The teacher downloads the data as CSV or XLSX.

## 6. MVP Scope

The MVP should include:

- Rails application with SQLite;
- Devise authentication;
- `AttendanceList`;
- `AttendanceField`;
- `AttendanceResponse`;
- `AttendanceAnswer`;
- attendance list CRUD;
- public attendance form;
- QR Code generation;
- exports;
- retention cleanup jobs.

## 7. Data Model

### User

Represents an organizer account.

Important rules:

- username is required and unique;
- email is not required for this version;
- password is required for account creation;
- inactivity tracking can be used for account deletion policies.

### AttendanceList

Represents one attendance list owned by a user.

Important fields:

- `user_id`;
- `title`;
- `description`;
- `public_token`;
- `starts_at`;
- `ends_at`;
- `time_zone`;
- `active`;
- `attendance_responses_count`.

Important rules:

- belongs to a user;
- has many fields and responses;
- generates a unique public token on creation;
- accepts at most five fields;
- `ends_at` must be after `starts_at`;
- `open?` controls whether the public form accepts responses;
- expired responses are purged after the retention window.

### AttendanceField

Represents a custom field configured for a list.

Important fields:

- `attendance_list_id`;
- `label`;
- `field_type`;
- `required`;
- `position`.

For the MVP, fields are text fields.

### AttendanceResponse

Represents one public submission.

Important fields:

- `attendance_list_id`;
- `submitted_at`;
- `ip_address`;
- `user_agent`.

Important rules:

- timestamp is set by the server;
- the associated list must be open;
- answers are deleted with the response.

### AttendanceAnswer

Represents one answer for one field in one response.

Important fields:

- `attendance_response_id`;
- `attendance_field_id`;
- `value`.

Required fields must have non-blank values.

## 8. Routes

Private organizer routes:

```txt
/attendance_lists
/attendance_lists/new
/attendance_lists/:id
/attendance_lists/:id/edit
/attendance_lists/:id/responses
/attendance_lists/:id/export
/attendance_lists/:id/qr_code_pdf
```

Public participant routes:

```txt
/a/:public_token
/a/:public_token/confirmed
```

Other routes:

```txt
/privacy
/up
```

## 9. Controllers

### AttendanceListsController

Handles authenticated organizer actions:

- index;
- show;
- new;
- create;
- edit;
- update;
- destroy;
- responses;
- export;
- QR Code PDF;
- close.

All private list lookups must use `current_user.attendance_lists`.

### PublicAttendanceController

Handles public attendance submission:

- `show` renders the form when the list is open;
- `create` records a response when valid;
- `confirmed` renders the final confirmation page;
- closed, inactive, future, or expired lists do not accept responses.

Successful public submissions redirect to `/a/:public_token/confirmed` with `303 See Other`.

### PrivacyController

Renders the `/privacy` notice explaining essential cookies and browser storage.

## 10. Services

### AttendanceListExport

Builds the header and rows shared by exports.

### AttendanceListXlsx

Creates a minimal XLSX file without introducing a heavy dependency.

### AttendanceListQrCodePdf

Generates a printable PDF containing the public QR Code.

### AttendanceResponsesPurger

Deletes expired responses and their answers.

### BrowserLocale

Resolves the preferred locale from the browser's `Accept-Language` header.

## 11. Views

Organizer views live under:

```txt
app/views/attendance_lists
```

Public participant views live under:

```txt
app/views/public_attendance
```

Important public views:

- `show.html.erb`: public attendance form;
- `closed.html.erb`: not started, expired, or inactive state;
- `confirmed.html.erb`: final confirmation after successful submission.

Privacy view:

```txt
app/views/privacy/show.html.erb
```

## 12. QR Code

The QR Code points to the absolute public attendance URL for a list. It is rendered in the list detail page and can also be exported to a printable PDF.

The project uses the `rqrcode` gem for QR generation.

## 13. Exports

CSV and XLSX exports include:

- response timestamp;
- one column per configured field;
- one row per response.

Exports are available only to the list owner.

## 14. Retention and Cleanup

Responses remain available for 48 hours after the list's `ends_at`. After that, a recurring job deletes `AttendanceResponse` and `AttendanceAnswer` records for expired lists.

This limits unnecessary personal data retention.

## 15. Privacy

The system may collect personal data, so public forms display a notice explaining that submitted information is used only for that attendance list.

Avoid sensitive fields in the MVP, such as:

- national ID numbers;
- full addresses;
- health data;
- financial data.

Current status:

- no analytics cookies;
- no advertising pixels;
- no behavioral profiling;
- no marketing trackers;
- session cookies and CSRF tokens are used for security;
- browser cache may store static assets;
- local browser storage may remember that the privacy notice was acknowledged;
- `/privacy` explains essential storage.

Any future analytics, marketing, pixel, tracker, or non-essential browser storage must be opt-in and must not load before user consent.

## 16. Internationalization

English is the default locale. Brazilian Portuguese is also supported.

All user-facing text should be stored in locale files. Tests should ensure Portuguese translation keys keep parity with English keys.

## 17. Testing

Expected test coverage:

- models for validations and domain rules;
- controllers for authentication, authorization, and responses;
- services for exports and cleanup;
- jobs for recurring behavior;
- I18n catalog parity;
- public attendance flow.

Run:

```bash
bin/rails test
```

If the environment blocks parallel test sockets:

```bash
PARALLEL_WORKERS=1 bin/rails test
```

## 18. Deployment Notes

The production architecture uses:

- Docker Compose;
- a prebuilt Rails image;
- Caddy for HTTPS;
- SQLite files persisted outside the container;
- local maintenance and backup routines on the VM.

Sensitive deploy details are intentionally not committed to the public repository.

## 19. Future Ideas

Possible future improvements:

- duplicate-response prevention based on a configured identifier field;
- QR Code image download;
- dashboard with list and response totals;
- admin-configured initial password flow;
- external object storage for uploads;
- PostgreSQL migration for multi-server or high-concurrency production use.

## 20. CS50 Summary

QuickPresence is a Rails and SQLite application created for the CS50 final project. It demonstrates authentication, relational modeling, public routes, server-rendered views, JavaScript enhancements, exports, QR Code generation, scheduled jobs, privacy considerations, tests, and deployment planning.
