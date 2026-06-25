import { env } from '../config/env'
import { AppError } from '../middleware/errorHandler'

type PayPalTokenResponse = { access_token: string }

type PayPalOrderResponse = {
  id: string
  links: Array<{ rel: string; href: string }>
}

type PayPalCaptureResponse = {
  id: string
  status: string
}

// Surfaces the real PayPal failure instead of a generic 500.
async function readPayPalError(res: Response, context: string): Promise<never> {
  const body = await res.text().catch(() => '')
  throw new AppError(
    502,
    `PayPal ${context} failed (HTTP ${res.status}): ${body || 'no response body'}`,
    'PAYPAL_ERROR',
  )
}

async function getPayPalToken(): Promise<string> {
  if (!env.PAYPAL_CLIENT_ID || !env.PAYPAL_CLIENT_SECRET) {
    throw new AppError(
      500,
      'PayPal is not configured: PAYPAL_CLIENT_ID / PAYPAL_CLIENT_SECRET are missing',
      'PAYPAL_NOT_CONFIGURED',
    )
  }

  const creds = Buffer.from(
    `${env.PAYPAL_CLIENT_ID}:${env.PAYPAL_CLIENT_SECRET}`,
  ).toString('base64')

  const res = await fetch(`${env.PAYPAL_BASE_URL}/v1/oauth2/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${creds}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  })

  if (!res.ok) await readPayPalError(res, 'auth')

  const data = (await res.json()) as PayPalTokenResponse
  if (!data.access_token) {
    throw new AppError(502, 'PayPal auth returned no access_token', 'PAYPAL_ERROR')
  }
  return data.access_token
}

export async function createPayPalOrder(amountUsd: number): Promise<{
  orderId: string
  approvalUrl: string
}> {
  const token = await getPayPalToken()

  const res = await fetch(`${env.PAYPAL_BASE_URL}/v2/checkout/orders`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      intent: 'CAPTURE',
      purchase_units: [
        {
          amount: {
            currency_code: 'USD',
            value: amountUsd.toFixed(2),
          },
        },
      ],
      application_context: {
        return_url: env.PAYPAL_RETURN_URL,
        cancel_url: env.PAYPAL_CANCEL_URL,
      },
    }),
  })

  if (!res.ok) await readPayPalError(res, 'create order')

  const data = (await res.json()) as PayPalOrderResponse
  const approvalUrl = data.links?.find(l => l.rel === 'approve')?.href
  if (!data.id || !approvalUrl) {
    throw new AppError(502, 'PayPal create order returned an unexpected response', 'PAYPAL_ERROR')
  }

  return { orderId: data.id, approvalUrl }
}

export async function capturePayPalOrder(paypalOrderId: string): Promise<{
  success: boolean
  transactionId: string
}> {
  const token = await getPayPalToken()

  const res = await fetch(
    `${env.PAYPAL_BASE_URL}/v2/checkout/orders/${paypalOrderId}/capture`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
    },
  )

  if (!res.ok) await readPayPalError(res, 'capture')

  const data = (await res.json()) as PayPalCaptureResponse

  return {
    success: data.status === 'COMPLETED',
    transactionId: data.id,
  }
}
