# Thin re-tag of the official Octobox image — no rebuild of the Rails app.
# bin/docker-start (the image CMD) waits for the DB, runs rake db:migrate,
# then starts rails. We only need the env vars (OCTOBOX_DATABASE_HOST =
# octobox-postgres.pod) to be correct — see nexlayer_fix.md.
FROM mirror.gcr.io/octoboxio/octobox:june-2026
EXPOSE 3000
