import https from 'https'
import {
  collectDefaultMetrics,
  Counter,
  Histogram,
  Gauge,
  Registry,
} from 'prom-client'

// Single registry shared across the app
export const registry = new Registry()

// Default Node.js metrics: heap, RSS, event-loop lag, GC, CPU usage
collectDefaultMetrics({ register: registry, prefix: 'moodfood_node_' })

// ─── HTTP metrics ─────────────────────────────────────────────────────────────

export const httpRequestsTotal = new Counter({
  name: 'moodfood_http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [registry],
})

export const httpRequestDurationSeconds = new Histogram({
  name: 'moodfood_http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.25, 0.5, 1, 2, 5],
  registers: [registry],
})

// ─── AI / Vision metrics ──────────────────────────────────────────────────────

export const aiCallsTotal = new Counter({
  name: 'moodfood_ai_calls_total',
  help: 'OpenAI API calls by type',
  labelNames: ['type', 'powered'],   // type: explanation | vision, powered: true | false
  registers: [registry],
})

export const aiCallDurationSeconds = new Histogram({
  name: 'moodfood_ai_call_duration_seconds',
  help: 'OpenAI API call duration in seconds',
  labelNames: ['type'],
  buckets: [0.1, 0.5, 1, 2, 5, 10, 20],
  registers: [registry],
})

export const aiErrorsTotal = new Counter({
  name: 'moodfood_ai_errors_total',
  help: 'OpenAI API errors by type',
  labelNames: ['type', 'error_code'],
  registers: [registry],
})

export const visionSourceTotal = new Counter({
  name: 'moodfood_vision_source_total',
  help: 'Vision requests by detected source (fridge / receipt / shopping_list / unknown)',
  labelNames: ['source'],
  registers: [registry],
})

export const visionIngredientsExtracted = new Histogram({
  name: 'moodfood_vision_ingredients_extracted',
  help: 'Number of ingredients extracted per photo',
  buckets: [0, 1, 2, 3, 5, 8, 12, 20],
  registers: [registry],
})

// ─── Business metrics ─────────────────────────────────────────────────────────

export const moodChecksTotal = new Counter({
  name: 'moodfood_mood_checks_total',
  help: 'Mood check-ins created',
  labelNames: ['mood'],
  registers: [registry],
})

export const recommendationsTotal = new Counter({
  name: 'moodfood_recommendations_total',
  help: 'AI recommendation requests',
  labelNames: ['ai_powered', 'via_photo'],
  registers: [registry],
})

export const favoritesTotal = new Counter({
  name: 'moodfood_favorites_total',
  help: 'Favorites added or removed',
  labelNames: ['action'],   // add | remove
  registers: [registry],
})

export const visionRequestsTotal = new Counter({
  name: 'moodfood_vision_requests_total',
  help: 'Photo recognition requests by endpoint',
  labelNames: ['endpoint'],   // ingredients | recommendations
  registers: [registry],
})

export const activeUsersGauge = new Gauge({
  name: 'moodfood_active_sessions',
  help: 'Approximate active sessions based on recent auth activity (last 60 s)',
  registers: [registry],
})

// ─── Grafana Cloud remote_write push (production) ────────────────────────────
//
// Pushes Prometheus text-format metrics to Grafana Cloud every 15 seconds.
// Uses the simple text-format push (not Snappy/protobuf) which Grafana Cloud
// accepts as a Pushgateway-compatible endpoint.
// Activated only when GRAFANA_REMOTE_WRITE_URL is set in the environment.

export function startGrafanaCloudPush(
  url: string,
  user: string,
  password: string,
  intervalMs = 15_000,
): void {
  if (!url || !user || !password) return

  const parsed = new URL(url)
  const auth = Buffer.from(`${user}:${password}`).toString('base64')

  const push = async () => {
    try {
      const body = await registry.metrics()
      const req = https.request(
        {
          hostname: parsed.hostname,
          path: parsed.pathname,
          method: 'POST',
          headers: {
            'Content-Type': registry.contentType,
            Authorization: `Basic ${auth}`,
            'Content-Length': Buffer.byteLength(body),
          },
        },
        (res) => {
          if (res.statusCode && res.statusCode >= 400) {
            console.error(`[metrics] Grafana Cloud push failed: HTTP ${res.statusCode}`)
          }
        },
      )
      req.on('error', (err) => console.error('[metrics] Grafana Cloud push error:', err.message))
      req.write(body)
      req.end()
    } catch (err) {
      console.error('[metrics] Failed to collect metrics for push:', err)
    }
  }

  setInterval(push, intervalMs)
  console.log(`[metrics] Pushing to Grafana Cloud every ${intervalMs / 1000}s`)
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Collapses dynamic path segments so Prometheus cardinality stays low.
 * /recipes/abc-123  →  /recipes/:id
 * /pantry/def-456   →  /pantry/:id
 */
export function normalizeRoute(path: string): string {
  return path
    .replace(/\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi, '/:id')
    .replace(/\/\d+/g, '/:id')
    .replace(/\?.*$/, '')
}
