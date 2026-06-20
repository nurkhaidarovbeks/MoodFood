import dotenv from 'dotenv'
dotenv.config()

const CLIENT_ID     = process.env.PAYPAL_CLIENT_ID     ?? ''
const CLIENT_SECRET = process.env.PAYPAL_CLIENT_SECRET ?? ''
const BASE_URL      = process.env.PAYPAL_BASE_URL       ?? 'https://api-m.sandbox.paypal.com'
const RETURN_URL    = process.env.PAYPAL_RETURN_URL     ?? 'http://localhost:3000/api/v1/payment/paypal/success'
const CANCEL_URL    = process.env.PAYPAL_CANCEL_URL     ?? 'http://localhost:3000/api/v1/payment/paypal/cancel'

async function run() {
  console.log('── PayPal Integration Test ──────────────────────')
  console.log(`Base URL : ${BASE_URL}`)
  console.log(`Client ID: ${CLIENT_ID.slice(0, 12)}...`)
  console.log('')

  // Step 1: get access token
  console.log('1. Getting access token...')
  const creds = Buffer.from(`${CLIENT_ID}:${CLIENT_SECRET}`).toString('base64')
  const tokenRes = await fetch(`${BASE_URL}/v1/oauth2/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${creds}`,
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'grant_type=client_credentials',
  })

  if (!tokenRes.ok) {
    const err = await tokenRes.text()
    console.error(`❌ Token failed (${tokenRes.status}): ${err}`)
    process.exit(1)
  }

  const { access_token } = await tokenRes.json() as { access_token: string }
  console.log(`✅ Token received: ${access_token.slice(0, 20)}...`)
  console.log('')

  // Step 2: create test order ($1.00)
  console.log('2. Creating test order ($1.00)...')
  const orderRes = await fetch(`${BASE_URL}/v2/checkout/orders`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${access_token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      intent: 'CAPTURE',
      purchase_units: [{ amount: { currency_code: 'USD', value: '1.00' } }],
      application_context: { return_url: RETURN_URL, cancel_url: CANCEL_URL },
    }),
  })

  if (!orderRes.ok) {
    const err = await orderRes.text()
    console.error(`❌ Order failed (${orderRes.status}): ${err}`)
    process.exit(1)
  }

  const order = await orderRes.json() as {
    id: string
    status: string
    links: Array<{ rel: string; href: string }>
  }

  const approvalUrl = order.links.find(l => l.rel === 'approve')?.href ?? ''
  console.log(`✅ Order created`)
  console.log(`   Order ID : ${order.id}`)
  console.log(`   Status   : ${order.status}`)
  console.log('')
  console.log('3. Approval URL (open in browser to test payment):')
  console.log(`   ${approvalUrl}`)
  console.log('')
  console.log('── Test PASSED ✅ PayPal credentials работают ────')
}

run().catch(err => {
  console.error('❌ Unexpected error:', err.message)
  process.exit(1)
})
