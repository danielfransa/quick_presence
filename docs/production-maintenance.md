# Production Maintenance Notes

This document records the production maintenance routine without exposing the
private deployment script or machine-specific details.

## Purpose

The production VM runs a daily maintenance routine after the application's
recurring jobs. The goal is to keep containers healthy, apply configured image
updates, create a local backup before restarts, and leave an audit trail in log
files.

The private script is intentionally ignored by Git:

```text
bin/production-maintenance
```

It should exist only on trusted local machines and on the production VM.

## Current Schedule

The application has recurring jobs in `config/recurring.yml`:

- expired attendance responses are purged every hour;
- inactive users are deleted every day at 03:00;
- finished Solid Queue jobs are cleared hourly.

The VM maintenance routine is scheduled after that daily deletion window:

```cron
0 7 * * * /home/ubuntu/quick_presence/bin/production-maintenance
```

The VM clock is UTC. `07:00 UTC` corresponds to `04:00` in Sao Paulo.

## Routine Behavior

The private script should:

- prevent overlapping runs with a lock;
- write logs to the deployment directory;
- pull the images configured in `compose.production.yml`;
- stop only the Rails web container before the SQLite backup;
- create a compressed backup of the persistent storage directory;
- start containers with Docker Compose;
- wait for the public health endpoint to return success;
- record recent `web` and `caddy` logs;
- prune only dangling Docker images;
- remove old maintenance logs and local backups according to retention settings;
- try to start containers again if a failure happens while the web container is
  stopped.

The routine must not remove Docker volumes or the persistent storage directory.

## Important Limits

Because the app uses versioned image tags, the daily routine does not discover a
new application version by itself. A new application release still requires
publishing a new Docker image and updating `APP_IMAGE` in the production `.env`.

The routine can still pull updates for mutable images such as the Caddy image,
depending on the tag in use.

## Local Backups

The routine creates local backups before restarting containers. These backups
are useful for quick recovery, but they do not protect against loss of the VM.

Keep an external backup process outside the VM for real disaster recovery.

## Validation

After installing or changing the private script, run it manually once and check:

```bash
cd ~/quick_presence
./bin/production-maintenance
docker compose -f compose.production.yml ps
tail -n 120 log/maintenance-$(date +%F).log
```

Expected result:

- `web` and `caddy` are running;
- the health check succeeds;
- a backup file is created;
- logs show a completed maintenance run.

## Safety Rules

Do not run these commands as part of automatic maintenance:

```bash
docker compose down -v
docker volume prune
docker system prune --volumes
rm -rf /var/lib/quick_presence
```

These commands can remove persistent data or make recovery harder.
