import { mockDeep, mockReset } from 'jest-mock-extended'
import { PrismaClient, OrderStatus, OrderType, PaymentGateway } from '@prisma/client'
import { PaymentService, VALID_TRANSITIONS } from '../src/modules/payment/payment.service'

jest.mock('../src/services/paypal.service', () => ({
  createPayPalOrder:  jest.fn(),
  capturePayPalOrder: jest.fn(),
}))

import {
  createPayPalOrder,
  capturePayPalOrder,
} from '../src/services/paypal.service'

const mockPPCreate  = createPayPalOrder  as jest.MockedFunction<typeof createPayPalOrder>
const mockPPCapture = capturePayPalOrder as jest.MockedFunction<typeof capturePayPalOrder>

const mockPrisma = mockDeep<PrismaClient>()
const service    = new PaymentService(mockPrisma as unknown as PrismaClient)

beforeEach(() => {
  mockReset(mockPrisma)
  jest.clearAllMocks()
})

const userId  = 'user-1'
const orderId = 'order-1'
const ppToken = 'pp-token-1'

function makeOrder(overrides: Partial<{
  id: string; userId: string; status: OrderStatus; orderType: OrderType;
  gateway: PaymentGateway; amount: number; currency: string;
  gatewayOrderId: string | null; paymentUrl: string | null; transactionId: string | null;
  description: string | null; createdAt: Date; updatedAt: Date;
}> = {}) {
  return {
    id:             orderId,
    userId,
    status:         OrderStatus.pending,
    orderType:      OrderType.purchase,
    gateway:        PaymentGateway.paypal,
    amount:         9.99,
    currency:       'USD',
    gatewayOrderId: ppToken,
    paymentUrl:     'https://paypal.com/approve',
    transactionId:  null,
    description:    'MoodFood',
    createdAt:      new Date(),
    updatedAt:      new Date(),
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

// ─── PAY-006: PayPal checkout + idempotency ───────────────────────────────────

describe('checkout — PayPal', () => {
  it('PAY-P1. creates order and returns PayPal approval URL', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(null)
    mockPrisma.order.create.mockResolvedValue(
      makeOrder({ status: OrderStatus.created, gatewayOrderId: null, paymentUrl: null }) as any,
    )
    mockPPCreate.mockResolvedValue({ orderId: ppToken, approvalUrl: 'https://paypal.com/approve' })
    mockPrisma.order.update.mockResolvedValue(makeOrder() as any)

    const result = await service.checkout(userId, { amount: 9.99 })

    expect(mockPPCreate).toHaveBeenCalledWith(9.99)
    expect(result.paymentUrl).toBe('https://paypal.com/approve')
    expect(result.idempotent).toBe(false)
  })

  it('PAY-P2. idempotency — returns existing pending order without calling PayPal', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder() as any)

    const result = await service.checkout(userId, { amount: 9.99 })

    expect(mockPPCreate).not.toHaveBeenCalled()
    expect(result.idempotent).toBe(true)
  })

  it('PAY-P3. description is forwarded to order', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(null)
    mockPrisma.order.create.mockResolvedValue(
      makeOrder({ status: OrderStatus.created, gatewayOrderId: null, paymentUrl: null, description: 'Premium plan' }) as any,
    )
    mockPPCreate.mockResolvedValue({ orderId: ppToken, approvalUrl: 'https://paypal.com/approve' })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ description: 'Premium plan' }) as any)

    await service.checkout(userId, { amount: 9.99, description: 'Premium plan' })

    expect(mockPrisma.order.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ description: 'Premium plan' }) }),
    )
  })
})

// ─── PAY-006: PayPal success + cancel ────────────────────────────────────────

describe('handlePaypalSuccess', () => {
  it('PAY-S1. marks order paid when PayPal capture succeeds', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder() as any)
    mockPPCapture.mockResolvedValue({ success: true, transactionId: 'txn-abc' })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.paid }) as any)

    const result = await service.handlePaypalSuccess(ppToken)

    expect(mockPPCapture).toHaveBeenCalledWith(ppToken)
    expect(mockPrisma.order.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ status: OrderStatus.paid, transactionId: 'txn-abc' }) }),
    )
    expect(result.success).toBe(true)
  })

  it('PAY-S2. marks order failed when PayPal capture fails', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder() as any)
    mockPPCapture.mockResolvedValue({ success: false, transactionId: '' })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.failed }) as any)

    const result = await service.handlePaypalSuccess(ppToken)

    expect(result.success).toBe(false)
    expect(result.status).toBe('failed')
  })

  it('PAY-S3. throws 404 when order not found', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(null)

    await expect(service.handlePaypalSuccess('nonexistent')).rejects.toMatchObject({
      statusCode: 404,
      code: 'ORDER_NOT_FOUND',
    })
  })
})

describe('handlePaypalCancel', () => {
  it('PAY-C1. marks pending order as failed on cancel', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder() as any)
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.failed }) as any)

    const result = await service.handlePaypalCancel(ppToken)

    expect(mockPrisma.order.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { status: OrderStatus.failed } }),
    )
    expect(result.success).toBe(false)
  })

  it('PAY-C2. does nothing when order not found', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(null)

    const result = await service.handlePaypalCancel('unknown')

    expect(mockPrisma.order.update).not.toHaveBeenCalled()
    expect(result.success).toBe(false)
  })
})

// ─── Orders ───────────────────────────────────────────────────────────────────

describe('getUserOrders', () => {
  it('PAY-O1. returns list of orders for user', async () => {
    mockPrisma.order.findMany.mockResolvedValue([makeOrder() as any, makeOrder({ id: 'order-2' }) as any])

    const result = await service.getUserOrders(userId)

    expect(result).toHaveLength(2)
  })
})

describe('getOrder', () => {
  it('PAY-O2. returns order belonging to user', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder() as any)
    const result = await service.getOrder(userId, orderId)
    expect(result.id).toBe(orderId)
  })

  it('PAY-O3. throws 404 when not found', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(null)
    await expect(service.getOrder(userId, 'x')).rejects.toMatchObject({ statusCode: 404 })
  })
})

// ─── Refund ───────────────────────────────────────────────────────────────────

describe('refundOrder', () => {
  it('PAY-R1. refunds paid order', async () => {
    mockPrisma.order.findUnique.mockResolvedValue(makeOrder({ status: OrderStatus.paid }) as any)
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.refunded }) as any)

    const result = await service.refundOrder(orderId, {})

    expect(mockPrisma.order.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { status: OrderStatus.refunded } }),
    )
    expect(result.message).toContain('refunded')
  })

  it('PAY-R2. throws 400 on invalid transition (pending → refunded)', async () => {
    mockPrisma.order.findUnique.mockResolvedValue(makeOrder({ status: OrderStatus.pending }) as any)
    await expect(service.refundOrder(orderId, {})).rejects.toMatchObject({
      statusCode: 400,
      code: 'INVALID_STATUS_TRANSITION',
    })
  })

  it('PAY-R3. throws 404 when order not found', async () => {
    mockPrisma.order.findUnique.mockResolvedValue(null)
    await expect(service.refundOrder('x', {})).rejects.toMatchObject({ statusCode: 404 })
  })
})
