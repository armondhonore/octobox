# Nexlayer fix — octobox (AUTHORITATIVE / PINNED)

Root cause (from container logs): the pipeline-stored config injected the broken
`${octobox-postgres:5432}` template into `OCTOBOX_DATABASE_HOST`. The platform
never resolves `${podName:port}` — it must be `<podName>.pod:<port>`. So
`bin/docker-start`'s `nc -z $OCTOBOX_DATABASE_HOST` looped forever
("Name does not resolve") and the DB migration / rails server never started.

Fix: use the prebuilt official image and reference the postgres pod as
`octobox-postgres.pod` (plain, no `${}`). bin/docker-start already waits for the
DB and runs `rake db:migrate` before `rails s`.

## Fixed Dockerfile
```dockerfile
# Thin re-tag of the official Octobox image (no rebuild of the app).
FROM mirror.gcr.io/octoboxio/octobox:june-2026
EXPOSE 3000
```

## Fixed nexlayer.yaml
```yaml
application:
  name: octobox
  pods:
  - name: app
    image: "# filled by pipeline"
    path: /
    servicePorts:
    - 3000
    vars:
      RAILS_ENV: production
      RAILS_SERVE_STATIC_FILES: "true"
      SECRET_KEY_BASE: "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2"
      OCTOBOX_DATABASE_NAME: octobox
      OCTOBOX_DATABASE_USERNAME: octobox
      OCTOBOX_DATABASE_PASSWORD: octoboxdbpass
      OCTOBOX_DATABASE_HOST: octobox-postgres.pod
      OCTOBOX_DATABASE_PORT: "5432"
      REDIS_URL: "redis://octobox-redis.pod:6379"
      GITHUB_CLIENT_ID: "placeholder"
      GITHUB_CLIENT_SECRET: "placeholder"
  - name: octobox-postgres
    image: mirror.gcr.io/library/postgres:16-alpine
    servicePorts:
    - 5432
    vars:
      POSTGRES_DB: octobox
      POSTGRES_USER: octobox
      POSTGRES_PASSWORD: octoboxdbpass
    volumes:
    - name: octobox-db-v2
      mountPath: /var/lib/postgresql/data
      size: 5Gi
  - name: octobox-redis
    image: mirror.gcr.io/library/redis:7-alpine
    servicePorts:
    - 6379
```
