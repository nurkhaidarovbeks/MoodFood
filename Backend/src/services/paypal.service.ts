import { env } from '../config/env'

type PayPalTokenResponse = { access_token: string }

type PayPalOrderResponse = {
  id: string
  links: Array<{ rel: string; href: string }>
}

type PayPalCaptureResponse = {
  id: string
  status: string
}

async function getPayPalToken(): Promise<string> {
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

  const data = (await res.json()) as PayPalTokenResponse
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

  const data = (await res.json()) as PayPalOrderResponse
  const approvalUrl = data.links.find(l => l.rel === 'approve')?.href ?? ''

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

  const data = (await res.json()) as PayPalCaptureResponse

  return {
    success: data.status === 'COMPLETED',
    transactionId: data.id,
  }
}
