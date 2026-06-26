import https from 'https'
import { compress } from 'snappyjs'
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
// Pushes metrics to Grafana Cloud every 15 seconds using the Prometheus
// remote_write protocol (protobuf + Snappy), which is what Grafana Cloud
// Mimir/Prometheus expects at /api/prom/push.
// Activated only when GRAFANA_REMOTE_WRITE_URL is set in the environment.

// ── Minimal protobuf encoder for Prometheus WriteRequest ──────────────────────
// WriteRequest { repeated TimeSeries timeseries = 1 }
// TimeSeries  { repeated Label labels = 1; repeated Sample samples = 2 }
// Label       { string name = 1; string value = 2 }
// Sample      { double value = 1; int64 timestamp = 2 }

function pbVarint(n: number): number[] {
  const out: number[] = []
  while (n > 0x7f) { out.push((n & 0x7f) | 0x80); n >>>= 7 }
  out.push(n & 0x7f)
  return out
}
function pbTag(field: number, wire: number) { return pbVarint((field << 3) | wire) }
function pbString(field: number, s: string): number[] {
  const b = Array.from(Buffer.from(s, 'utf8'))
  return [...pbTag(field, 2), ...pbVarint(b.length), ...b]
}
function pbDouble(field: number, v: number): number[] {
  const buf = Buffer.allocUnsafe(8); buf.writeDoubleBE(v, 0)
  // wire type 1 = 64-bit, little-endian on the wire
  const le = Buffer.allocUnsafe(8); buf.copy(le); le.reverse()
  return [...pbTag(field, 1), ...le]
}
function pbInt64(field: number, v: number): number[] {
  // Encode as varint (works for positive timestamps up to ~2^53)
  const out: number[] = [...pbTag(field, 0)]
  let n = v
  while (n > 0x7f) { out.push((n & 0x7f) | 0x80); n = Math.floor(n / 128) }
  out.push(n & 0x7f)
  return out
}
function pbEmbed(field: number, bytes: number[]): number[] {
  return [...pbTag(field, 2), ...pbVarint(bytes.length), ...bytes]
}

function buildWriteRequest(samples: Array<{ name: string; labels: Record<string, string>; value: number; timestamp: number }>): Buffer {
  const tsList: number[] = []
  for (const s of samples) {
    const labelBytes: number[] = [
      ...pbString(1, '__name__'), ...pbString(2, s.name),
      ...Object.entries(s.labels).flatMap(([k, v]) => [...pbString(1, k), ...pbString(2, v)]),
    ]
    const sampleBytes: number[] = [...pbDouble(1, s.value), ...pbInt64(2, s.timestamp)]
    const ts: number[] = [...pbEmbed(1, labelBytes), ...pbEmbed(2, sampleBytes)]
    tsList.push(...pbEmbed(1, ts))
  }
  return Buffer.from(tsList)
}

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
      const jsonMetrics = await registry.getMetricsAsJSON()
      const now = Date.now()
      const samples: Array<{ name: string; labels: Record<string, string>; value: number; timestamp: number }> = []

      for (const metric of jsonMetrics) {
        for (const val of metric.values as Array<{ labels: Record<string, string>; value: number }>) {
          if (typeof val.value !== 'number' || !isFinite(val.value)) continue
          const safeName = metric.name.replace(/[^a-zA-Z0-9_:]/g, '_')
          samples.push({ name: safeName, labels: val.labels ?? {}, value: val.value, timestamp: now })
        }
      }

      if (samples.length === 0) return

      const proto = buildWriteRequest(samples)
      const compressed = compress(proto)
      const body = Buffer.isBuffer(compressed) ? compressed : Buffer.from(compressed)

      const req = https.request(
        {
          hostname: parsed.hostname,
          path: parsed.pathname + (parsed.search || ''),
          method: 'POST',
          headers: {
            'Content-Type': 'application/x-protobuf',
            'Content-Encoding': 'snappy',
            'X-Prometheus-Remote-Write-Version': '0.1.0',
            Authorization: `Basic ${auth}`,
            'Content-Length': body.length,
          },
        },
        (res) => {
          if (res.statusCode && res.statusCode >= 400) {
            res.resume()
            console.error(`[metrics] Grafana Cloud push failed: HTTP ${res.statusCode}`)
          }
        },
      )
      req.on('error', (err) => console.error('[metrics] Grafana Cloud push error:', err.message))
      req.write(body)
      req.end()
    } catch (err) {
      console.error('[metrics] Failed to push metrics:', err)
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
