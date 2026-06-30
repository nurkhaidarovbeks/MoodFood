import https from 'https'
import { env } from '../config/env'
import { pushSentTotal } from './metrics.service'

export interface PushMessage {
  title: string
  body: string
  data?: Record<string, string>
}

export interface PushResult {
  /** True when at least one token was accepted by FCM (or when no provider is
   *  configured but tokens exist — the call is treated as a no-op success). */
  delivered: boolean
  tokens: number
  /** True when a real FCM request was made (provider configured). */
  providerConfigured: boolean
}

/**
 * PushService — sends push notifications via Firebase Cloud Messaging (legacy
 * HTTP API). Mirrors the AI service pattern: when FCM_SERVER_KEY is unset the
 * service is "disabled" and send() becomes a logged no-op, so the rest of the
 * app (device registration, reminder computation, the /due polling endpoint)
 * works fully offline and in tests. Inject a fake `client` to unit-test it.
 */
export class PushService {
  readonly enabled: boolean
  private serverKey: string

  constructor(opts: { serverKey?: string } = {}) {
    this.serverKey = opts.serverKey ?? env.FCM_SERVER_KEY
    this.enabled = this.serverKey.length > 0
  }

  /** Sends one message to many device tokens. Never throws — logs and reports. */
  async send(tokens: string[], message: PushMessage, type = 'custom'): Promise<PushResult> {
    const unique = [...new Set(tokens.filter(Boolean))]
    if (unique.length === 0) {
      pushSentTotal.inc({ type, outcome: 'skipped' })
      return { delivered: false, tokens: 0, providerConfigured: this.enabled }
    }

    if (!this.enabled) {
      // No provider configured — log and succeed silently (offline / dev / tests).
      console.log(`[push] (disabled) ${type}: "${message.title}" → ${unique.length} device(s)`)
      pushSentTotal.inc({ type, outcome: 'skipped' })
      return { delivered: false, tokens: unique.length, providerConfigured: false }
    }

    try {
      await this.postToFcm(unique, message)
      pushSentTotal.inc({ type, outcome: 'sent' })
      return { delivered: true, tokens: unique.length, providerConfigured: true }
    } catch (err) {
      console.error('[push] FCM send failed:', (err as Error).message)
      pushSentTotal.inc({ type, outcome: 'failed' })
      return { delivered: false, tokens: unique.length, providerConfigured: true }
    }
  }

  private postToFcm(tokens: string[], message: PushMessage): Promise<void> {
    const payload = JSON.stringify({
      registration_ids: tokens,
      notification: { title: message.title, body: message.body },
      data: message.data ?? {},
    })

    return new Promise((resolve, reject) => {
      const req = https.request(
        {
          hostname: 'fcm.googleapis.com',
          path: '/fcm/send',
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `key=${this.serverKey}`,
            'Content-Length': Buffer.byteLength(payload),
          },
        },
        res => {
          let body = ''
          res.on('data', c => {
            if (body.length < 500) body += c
          })
          res.on('end', () => {
            if (res.statusCode && res.statusCode >= 400) {
              reject(new Error(`HTTP ${res.statusCode} — ${body.trim()}`))
            } else {
              resolve()
            }
          })
        },
      )
      req.on('error', reject)
      req.write(payload)
      req.end()
    })
  }
}
