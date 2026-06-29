# Nexlayer fix — octobox (AUTHORITATIVE / PINNED)

Root cause (from container logs): a stored recipe injected the broken
`${octobox-postgres:5432}` template into `OCTOBOX_DATABASE_HOST`. The platform
never resolves `${podName:port}` — it must be `<podName>.pod:<port>`. So
`bin/docker-start`'s `nc -z $OCTOBOX_DATABASE_HOST` looped forever
("Name does not resolve") and the rails server / `rake db:migrate` never ran.

Fix: use the prebuilt official image directly (no source rebuild — the repo
Gemfile pins ruby 4.0.5 which does not exist) and set the DB host to the plain
pod-DNS form `octobox-postgres.pod`. bin/docker-start already waits for the DB
and runs `rake db:migrate` before `rails s`. Use literal matching DB passwords
on both pods (secret provisioning is unavailable without a GitHub token, so a
`${POSTGRES_PASSWORD}` ref would never resolve).

## Fixed Dockerfile
```dockerfile
FROM mirror.gcr.io/octoboxio/octobox:june-2026
EXPOSE 3000
```

## Fixed nexlayer.yaml
```yaml
application:
  name: octobox
  pods:
  - name: app
    image: mirror.gcr.io/octoboxio/octobox:june-2026
    path: /
    servicePorts:
    - 3000
    vars:
      RAILS_ENV: production
      RAILS_SERVE_STATIC_FILES: "true"
      SECRET_KEY_BASE: octoboxplaceholdersecretkeybaseforpreviewdeploytestonly
      OCTOBOX_DATABASE_NAME: octobox
      OCTOBOX_DATABASE_USERNAME: octobox
      OCTOBOX_DATABASE_HOST: octobox-postgres.pod
      OCTOBOX_DATABASE_PORT: "5432"
      GITHUB_CLIENT_ID: "placeholder"
      GITHUB_CLIENT_SECRET: "placeholder"
  - name: octobox-postgres
    image: mirror.gcr.io/library/postgres:16-alpine
    servicePorts:
    - 5432
    vars:
      POSTGRES_DB: octobox
      POSTGRES_USER: octobox
      POSTGRES_HOST_AUTH_METHOD: trust
    volumes:
    - name: octobox-db-v2
      mountPath: /var/lib/postgresql/data
      size: 5Gi
```
