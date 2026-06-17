import { mockDeep, mockReset } from 'jest-mock-extended'
import { PrismaClient, OrderStatus, PaymentGateway } from '@prisma/client'
import { PaymentService, VALID_TRANSITIONS } from '../src/modules/payment/payment.service'

// ─── Mock external payment services ──────────────────────────────────────────
jest.mock('../src/services/bereke.service', () => ({
  bereRegisterOrder: jest.fn(),
  bereGetStatus: jest.fn(),
  bereRefund: jest.fn(),
}))
jest.mock('../src/services/paypal.service', () => ({
  createPayPalOrder: jest.fn(),
  capturePayPalOrder: jest.fn(),
}))

import {
  bereRegisterOrder,
  bereGetStatus,
  bereRefund,
} from '../src/services/bereke.service'
import {
  createPayPalOrder,
  capturePayPalOrder,
} from '../src/services/paypal.service'

const mockBereRegister = bereRegisterOrder as jest.MockedFunction<typeof bereRegisterOrder>
const mockBereStatus  = bereGetStatus     as jest.MockedFunction<typeof bereGetStatus>
const mockBereRefund  = bereRefund        as jest.MockedFunction<typeof bereRefund>
const mockPPCreate    = createPayPalOrder  as jest.MockedFunction<typeof createPayPalOrder>
const mockPPCapture   = capturePayPalOrder as jest.MockedFunction<typeof capturePayPalOrder>

// ─── Setup ────────────────────────────────────────────────────────────────────

const mockPrisma = mockDeep<PrismaClient>()
const service    = new PaymentService(mockPrisma as unknown as PrismaClient)

beforeEach(() => {
  mockReset(mockPrisma)
  jest.clearAllMocks()
})

// ─── Helpers ──────────────────────────────────────────────────────────────────

const userId  = 'user-1'
const orderId = 'order-1'
const gwId    = 'gw-order-123'

function makeOrder(overrides: Partial<{
  id: string
  userId: string
  status: OrderStatus
  gateway: PaymentGateway
  amount: number
  currency: string
  gatewayOrderId: string | null
  paymentUrl: string | null
  transactionId: string | null
  description: string | null
  createdAt: Date
  updatedAt: Date
}> = {}) {
  return {
    id:             orderId,
    userId,
    status:         OrderStatus.pending,
    gateway:        PaymentGateway.bereke,
    amount:         4900,
    currency:       'KZT',
    gatewayOrderId: gwId,
    paymentUrl:     'https://3dsec.berekebank.kz/pay?orderId=gw-order-123',
    transactionId:  null,
    description:    'MoodFood',
    createdAt:      new Date('2026-06-17T10:00:00Z'),
    updatedAt:      new Date('2026-06-17T10:00:00Z'),
    ...overrides,
  }
}

// ─── PAY-004: State machine ───────────────────────────────────────────────────

describe('VALID_TRANSITIONS', () => {
  it('PAY-T1. pending → paid is allowed', () => {
    expect(VALID_TRANSITIONS[OrderStatus.pending]).toContain(OrderStatus.paid)
  })

  it('PAY-T2. pending → failed is allowed', () => {
    expect(VALID_TRANSITIONS[OrderStatus.pending]).toContain(OrderStatus.failed)
  })

  it('PAY-T3. paid → fulfilled is allowed', () => {
    expect(VALID_TRANSITIONS[OrderStatus.paid]).toContain(OrderStatus.fulfilled)
  })

  it('PAY-T4. paid → refunded is allowed', () => {
    expect(VALID_TRANSITIONS[OrderStatus.paid]).toContain(OrderStatus.refunded)
  })

  it('PAY-T5. refunded has no further transitions', () => {
    expect(VALID_TRANSITIONS[OrderStatus.refunded]).toHaveLength(0)
  })

  it('PAY-T6. cancelled has no further transitions', () => {
    expect(VALID_TRANSITIONS[OrderStatus.cancelled]).toHaveLength(0)
  })
})

// ─── PAY-002 + PAY-005: Bereke checkout + idempotency ────────────────────────

describe('checkout — Bereke', () => {
  it('PAY-B1. creates order and returns Bereke payment URL', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(null) // no existing pending order
    mockPrisma.order.create.mockResolvedValue(makeOrder({ status: OrderStatus.created, gatewayOrderId: null, paymentUrl: null }) as any)
    mockBereRegister.mockResolvedValue({ gatewayOrderId: gwId, paymentUrl: 'https://pay.bereke/form' })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ paymentUrl: 'https://pay.bereke/form' }) as any)

    const result = await service.checkout(userId, { amount: 4900, gateway: 'bereke' })

    expect(mockBereRegister).toHaveBeenCalledWith(orderId, 4900, undefined)
    expect(result.paymentUrl).toBe('https://pay.bereke/form')
    expect(result.status).toBe(OrderStatus.pending)
    expect(result.idempotent).toBe(false)
  })

  it('PAY-B2. creates order with description forwarded to Bereke', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(null)
    mockPrisma.order.create.mockResolvedValue(makeOrder({ status: OrderStatus.created, gatewayOrderId: null, paymentUrl: null }) as any)
    mockBereRegister.mockResolvedValue({ gatewayOrderId: gwId, paymentUrl: 'https://pay.bereke/form' })
    mockPrisma.order.update.mockResolvedValue(makeOrder() as any)

    await service.checkout(userId, { amount: 4900, gateway: 'bereke', description: 'Premium plan' })

    expect(mockBereRegister).toHaveBeenCalledWith(orderId, 4900, 'Premium plan')
  })

  it('PAY-B3. idempotency — returns existing pending order without calling Bereke', async () => {
    const existing = makeOrder()
    mockPrisma.order.findFirst.mockResolvedValue(existing as any)

    const result = await service.checkout(userId, { amount: 4900, gateway: 'bereke' })

    expect(mockBereRegister).not.toHaveBeenCalled()
    expect(result.orderId).toBe(orderId)
    expect(result.idempotent).toBe(true)
  })
})

// ─── PAY-006: PayPal checkout ─────────────────────────────────────────────────

describe('checkout — PayPal', () => {
  it('PAY-P1. creates order and returns PayPal approval URL', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(null)
    mockPrisma.order.create.mockResolvedValue(
      makeOrder({ gateway: PaymentGateway.paypal, currency: 'USD', status: OrderStatus.created, gatewayOrderId: null, paymentUrl: null }) as any,
    )
    mockPPCreate.mockResolvedValue({ orderId: 'pp-order-1', approvalUrl: 'https://paypal.com/approve' })
    mockPrisma.order.update.mockResolvedValue(
      makeOrder({ gateway: PaymentGateway.paypal, currency: 'USD', gatewayOrderId: 'pp-order-1', paymentUrl: 'https://paypal.com/approve' }) as any,
    )

    const result = await service.checkout(userId, { amount: 9.99, gateway: 'paypal' })

    expect(mockPPCreate).toHaveBeenCalledWith(9.99)
    expect(result.paymentUrl).toBe('https://paypal.com/approve')
    expect(result.idempotent).toBe(false)
  })

  it('PAY-P2. PayPal idempotency — returns existing pending order', async () => {
    const existing = makeOrder({ gateway: PaymentGateway.paypal })
    mockPrisma.order.findFirst.mockResolvedValue(existing as any)

    const result = await service.checkout(userId, { amount: 9.99, gateway: 'paypal' })

    expect(mockPPCreate).not.toHaveBeenCalled()
    expect(result.idempotent).toBe(true)
  })
})

// ─── PAY-002: Bereke success / fail redirect ──────────────────────────────────

describe('handleBereSuccess', () => {
  it('PAY-S1. marks order paid when Bereke confirms orderStatus=2', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder() as any)
    mockBereStatus.mockResolvedValue({ orderStatus: 2, amountKzt: 4900, actionCode: 0 })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.paid }) as any)

    const result = await service.handleBereSuccess(gwId)

    expect(mockBereStatus).toHaveBeenCalledWith(gwId)
    expect(mockPrisma.order.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { status: OrderStatus.paid } }),
    )
    expect(result.success).toBe(true)
    expect(result.status).toBe('paid')
  })

  it('PAY-S2. marks order failed when Bereke returns non-2 status', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder() as any)
    mockBereStatus.mockResolvedValue({ orderStatus: 6, amountKzt: 0, actionCode: 71015 })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.failed }) as any)

    const result = await service.handleBereSuccess(gwId)

    expect(result.success).toBe(false)
    expect(result.status).toBe('failed')
  })

  it('PAY-S3. throws 404 when order not found', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(null)

    await expect(service.handleBereSuccess('nonexistent')).rejects.toMatchObject({
      statusCode: 404,
      code: 'ORDER_NOT_FOUND',
    })
  })
})

describe('handleBereFail', () => {
  it('PAY-F1. marks pending order as failed on Bereke fail redirect', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder() as any)
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.failed }) as any)

    const result = await service.handleBereFail(gwId)

    expect(mockPrisma.order.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { status: OrderStatus.failed } }),
    )
    expect(result.success).toBe(false)
  })

  it('PAY-F2. does nothing when order not found (no crash)', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(null)

    const result = await service.handleBereFail('nonexistent')

    expect(mockPrisma.order.update).not.toHaveBeenCalled()
    expect(result.success).toBe(false)
  })
})

// ─── PAY-003: Bereke server callback ─────────────────────────────────────────

describe('handleBereCallback', () => {
  it('PAY-C1. marks order paid on deposited+status=1 after API double-check', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder() as any)
    mockBereStatus.mockResolvedValue({ orderStatus: 2, amountKzt: 4900, actionCode: 0 })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.paid }) as any)

    const result = await service.handleBereCallback({
      mdOrder: gwId,
      orderNumber: orderId,
      operation: 'deposited',
      status: '1',
    })

    expect(mockBereStatus).toHaveBeenCalledWith(gwId)
    expect(mockPrisma.order.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ status: OrderStatus.paid }) }),
    )
    expect(result).toEqual({ status: 'ok' })
  })

  it('PAY-C2. marks order refunded on reversed operation', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder({ status: OrderStatus.paid }) as any)
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.refunded }) as any)

    const result = await service.handleBereCallback({
      mdOrder: gwId,
      operation: 'reversed',
      status: '1',
    })

    expect(mockPrisma.order.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { status: OrderStatus.refunded } }),
    )
    expect(result).toEqual({ status: 'ok' })
  })

  it('PAY-C3. returns ok without crashing when order not found', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(null)

    const result = await service.handleBereCallback({ mdOrder: 'unknown', operation: 'deposited', status: '1' })

    expect(mockPrisma.order.update).not.toHaveBeenCalled()
    expect(result).toEqual({ status: 'ok' })
  })
})

// ─── PAY-006: PayPal success capture ─────────────────────────────────────────

describe('handlePaypalSuccess', () => {
  it('PAY-PP1. captures payment and marks order paid', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(
      makeOrder({ gateway: PaymentGateway.paypal, gatewayOrderId: 'pp-token-1' }) as any,
    )
    mockPPCapture.mockResolvedValue({ success: true, transactionId: 'txn-abc' })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.paid }) as any)

    const result = await service.handlePaypalSuccess('pp-token-1')

    expect(mockPPCapture).toHaveBeenCalledWith('pp-token-1')
    expect(mockPrisma.order.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ status: OrderStatus.paid, transactionId: 'txn-abc' }) }),
    )
    expect(result.success).toBe(true)
  })

  it('PAY-PP2. marks order failed when PayPal capture fails', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(
      makeOrder({ gateway: PaymentGateway.paypal }) as any,
    )
    mockPPCapture.mockResolvedValue({ success: false, transactionId: '' })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.failed }) as any)

    const result = await service.handlePaypalSuccess('pp-token-fail')

    expect(result.success).toBe(false)
    expect(result.status).toBe('failed')
  })
})

// ─── Orders: list + single ────────────────────────────────────────────────────

describe('getUserOrders', () => {
  it('PAY-O1. returns list of orders for user', async () => {
    mockPrisma.order.findMany.mockResolvedValue([makeOrder() as any, makeOrder({ id: 'order-2' }) as any])

    const result = await service.getUserOrders(userId)

    expect(result).toHaveLength(2)
    expect(mockPrisma.order.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { userId } }),
    )
  })
})

describe('getOrder', () => {
  it('PAY-O2. returns order belonging to user', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder() as any)

    const result = await service.getOrder(userId, orderId)

    expect(result.id).toBe(orderId)
  })

  it('PAY-O3. throws 404 when order not found or belongs to another user', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(null)

    await expect(service.getOrder(userId, 'other-order')).rejects.toMatchObject({
      statusCode: 404,
      code: 'ORDER_NOT_FOUND',
    })
  })
})

// ─── L2: Refund ───────────────────────────────────────────────────────────────

describe('refundOrder', () => {
  it('PAY-R1. refunds paid Bereke order via API and marks refunded', async () => {
    mockPrisma.order.findUnique.mockResolvedValue(makeOrder({ status: OrderStatus.paid }) as any)
    mockBereRefund.mockResolvedValue({ success: true })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.refunded }) as any)

    const result = await service.refundOrder(orderId, {})

    expect(mockBereRefund).toHaveBeenCalledWith(gwId, undefined)
    expect(mockPrisma.order.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { status: OrderStatus.refunded } }),
    )
    expect(result.message).toContain('refunded')
  })

  it('PAY-R2. partial refund passes amount to Bereke', async () => {
    mockPrisma.order.findUnique.mockResolvedValue(makeOrder({ status: OrderStatus.paid }) as any)
    mockBereRefund.mockResolvedValue({ success: true })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.refunded }) as any)

    await service.refundOrder(orderId, { amount: 2000 })

    expect(mockBereRefund).toHaveBeenCalledWith(gwId, 2000)
  })

  it('PAY-R3. throws 502 when Bereke refund API fails', async () => {
    mockPrisma.order.findUnique.mockResolvedValue(makeOrder({ status: OrderStatus.paid }) as any)
    mockBereRefund.mockResolvedValue({ success: false })

    await expect(service.refundOrder(orderId, {})).rejects.toMatchObject({
      statusCode: 502,
      code: 'REFUND_FAILED',
    })
  })

  it('PAY-R4. throws 400 on invalid state transition (pending → refunded)', async () => {
    mockPrisma.order.findUnique.mockResolvedValue(makeOrder({ status: OrderStatus.pending }) as any)

    await expect(service.refundOrder(orderId, {})).rejects.toMatchObject({
      statusCode: 400,
      code: 'INVALID_STATUS_TRANSITION',
    })
  })

  it('PAY-R5. throws 404 when order not found', async () => {
    mockPrisma.order.findUnique.mockResolvedValue(null)

    await expect(service.refundOrder('nonexistent', {})).rejects.toMatchObject({
      statusCode: 404,
      code: 'ORDER_NOT_FOUND',
    })
  })
})
