import { env } from '../config/env'

type BereRegisterResponse = {
  errorCode?: string
  errorMessage?: string
  orderId?: string
  formUrl?: string
}

type BereStatusResponse = {
  orderStatus?: number
  amount?: number
  actionCode?: number
}

type BereRefundResponse = {
  errorCode?: string
}

export async function bereRegisterOrder(
  orderId: string,
  amountKzt: number,
  description: string = 'MoodFood',
): Promise<{ gatewayOrderId: string; paymentUrl: string }> {
  const params = new URLSearchParams({
    userName: env.BEREKE_USERNAME,
    password: env.BEREKE_PASSWORD,
    orderNumber: orderId,
    amount: String(Math.round(amountKzt * 100)), // tiyn: 1 KZT = 100 tiyn
    currency: '398', // ISO 4217: KZT
    returnUrl: env.BEREKE_RETURN_URL,
    failUrl: env.BEREKE_FAIL_URL,
    description,
    language: 'en',
  })

  const res = await fetch(`${env.BEREKE_BASE_URL}/register.do`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params,
  })

  const data = (await res.json()) as BereRegisterResponse

  if ((data.errorCode ?? '0') !== '0') {
    throw new Error(data.errorMessage ?? 'Bereke order registration failed')
  }

  return {
    gatewayOrderId: data.orderId!,
    paymentUrl: data.formUrl!,
  }
}

export async function bereGetStatus(gatewayOrderId: string): Promise<{
  orderStatus: number
  amountKzt: number
  actionCode: number
}> {
  const params = new URLSearchParams({
    userName: env.BEREKE_USERNAME,
    password: env.BEREKE_PASSWORD,
    orderId: gatewayOrderId,
    language: 'en',
  })

  const res = await fetch(`${env.BEREKE_BASE_URL}/getOrderStatusExtended.do`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params,
  })

  const data = (await res.json()) as BereStatusResponse

  return {
    orderStatus: data.orderStatus ?? -1,
    amountKzt: (data.amount ?? 0) / 100,
    actionCode: data.actionCode ?? -1,
  }
}

// amountKzt is optional — omit for full refund, pass value for partial refund
export async function bereRefund(
  gatewayOrderId: string,
  amountKzt?: number,
): Promise<{ success: boolean }> {
  const params = new URLSearchParams({
    userName: env.BEREKE_USERNAME,
    password: env.BEREKE_PASSWORD,
    orderId: gatewayOrderId,
  })

  if (amountKzt !== undefined) {
    params.set('amount', String(Math.round(amountKzt * 100)))
  }

  const res = await fetch(`${env.BEREKE_BASE_URL}/refund.do`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params,
  })

  const data = (await res.json()) as BereRefundResponse
  return { success: data.errorCode === '0' }
}
