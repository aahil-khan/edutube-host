# Production Monitoring

This project now includes a baseline open-source monitoring stack designed for
single-node Docker Compose deployments that may run multiple frontend/backend replicas.

## Included Components

- Prometheus (`http://localhost:9090`)
- Grafana (`http://localhost:3001`, default `admin/admin`)
- Loki (`http://localhost:3100`)
- Alertmanager (`http://localhost:9093`)
- Promtail (log shipping)
- cAdvisor (container metrics source)

## Multi-Instance Behavior

- Prometheus discovers backend containers through Docker service discovery.
- Each backend instance exports `/metrics` and labels include `instance` (hostname/container id).
- Promtail discovers all Docker containers and tags logs by compose service/container.
- Nginx logs include `upstream_addr`, so you can see which backend/frontend instance served traffic.

## Key Signals Added

- Request rate: `http_requests_total`
- Latency: `http_request_duration_seconds` histogram
- In-flight requests: `http_in_flight_requests`
- Default Node.js process/runtime metrics via `prom-client`
- Container CPU/memory and health metrics via cAdvisor + scrape jobs

## Alerts (MVP)

- Backend instance down
- High backend 5xx ratio
- High backend p95 latency
- High container CPU
- High container memory

Alert rules are in `monitoring/prometheus/alerts.yml`.

## Operational Notes

- If you scale backend replicas, Prometheus will automatically discover them.
- Frontend replicas are monitored at container level; add app-level frontend metrics later if needed.
- Replace Alertmanager `default-log` receiver with Slack/email/webhook receiver for real notifications.
- Change Grafana default admin password in production.
- A starter Grafana dashboard is auto-provisioned at UID `edutube-starter`.
- Admin UI quick access is available at `/admin-dashboard/monitoring`.
