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

// ── Protobuf encoder for Prometheus WriteRequest ───────────────────────────────
// WriteRequest { repeated TimeSeries timeseries = 1 }
// TimeSeries  { repeated Label labels = 1; repeated Sample samples = 2 }
// Label       { string name = 1; string value = 2 }
// Sample      { double value = 1; int64 timestamp = 2 }
//
// Key: use % / Math.floor instead of bitwise & / >>> for large numbers
// because JS bitwise ops cast to Int32, breaking timestamps (> 2^31 ms).

function pbVarint(n: number): Buffer {
  const bytes: number[] = []
  while (n > 127) {
    bytes.push((n % 128) | 0x80)   // % avoids Int32 truncation
    n = Math.floor(n / 128)
  }
  bytes.push(n % 128)
  return Buffer.from(bytes)
}

function pbTag(field: number, wire: number): Buffer {
  return pbVarint(field * 8 + wire) // avoid << which also uses Int32
}

function pbLenDelim(field: number, payload: Buffer): Buffer {
  return Buffer.concat([pbTag(field, 2), pbVarint(payload.length), payload])
}

function pbString(field: number, s: string): Buffer {
  return pbLenDelim(field, Buffer.from(s, 'utf8'))
}

function pbDouble(field: number, v: number): Buffer {
  const tag = pbTag(field, 1)           // wire type 1 = 64-bit
  const data = Buffer.allocUnsafe(8)
  data.writeDoubleLE(v, 0)              // protobuf stores doubles little-endian
  return Buffer.concat([tag, data])
}

function pbInt64(field: number, v: number): Buffer {
  return Buffer.concat([pbTag(field, 0), pbVarint(v)])  // wire type 0 = varint
}

function buildWriteRequest(
  samples: Array<{ name: string; labels: Record<string, string>; value: number; timestamp: number }>,
): Buffer {
  const tsBufs: Buffer[] = []

  for (const s of samples) {
    // Build the full label set (incl. __name__), drop empty values, then sort
    // lexicographically by name — Mimir/Prometheus remote_write REQUIRES this.
    const allLabels: Array<[string, string]> = [['__name__', s.name]]
    for (const [k, v] of Object.entries(s.labels)) {
      const value = String(v)
      if (value.length > 0) allLabels.push([String(k), value])
    }
    allLabels.sort((a, b) => (a[0] < b[0] ? -1 : a[0] > b[0] ? 1 : 0))

    const labelBufs: Buffer[] = []
    for (const [k, v] of allLabels) {
      labelBufs.push(pbString(1, k), pbString(2, v))
    }

    const labelPayload = Buffer.concat(labelBufs)
    const samplePayload = Buffer.concat([pbDouble(1, s.value), pbInt64(2, s.timestamp)])

    const tsPayload = Buffer.concat([
      pbLenDelim(1, labelPayload),
      pbLenDelim(2, samplePayload),
    ])
    tsBufs.push(pbLenDelim(1, tsPayload))
  }

  return Buffer.concat(tsBufs)
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
            'X-Prometheus-Remote-Write-Version': '0.1.0',
            Authorization: `Basic ${auth}`,
            'Content-Length': body.length,
          },
        },
        (res) => {
          if (res.statusCode && res.statusCode >= 400) {
            let errBody = ''
            res.on('data', (chunk) => { if (errBody.length < 500) errBody += chunk })
            res.on('end', () =>
              console.error(`[metrics] Grafana Cloud push failed: HTTP ${res.statusCode} — ${errBody.trim()}`),
            )
          } else {
            res.resume()
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
