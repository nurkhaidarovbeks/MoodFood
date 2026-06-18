import { mockDeep, mockReset } from 'jest-mock-extended'
import { PrismaClient, OrderStatus, OrderType, PaymentGateway, SubscriptionStatus } from '@prisma/client'
import { SubscriptionService } from '../src/modules/subscription/subscription.service'
import { PaymentService } from '../src/modules/payment/payment.service'

// ─── Mock external payment services ──────────────────────────────────────────
jest.mock('../src/services/bereke.service', () => ({
  bereRegisterOrder: jest.fn(),
  bereGetStatus:     jest.fn(),
  bereRefund:        jest.fn(),
}))
jest.mock('../src/services/paypal.service', () => ({
  createPayPalOrder:  jest.fn(),
  capturePayPalOrder: jest.fn(),
}))

import { bereRegisterOrder, bereGetStatus } from '../src/services/bereke.service'
const mockBereRegister = bereRegisterOrder as jest.MockedFunction<typeof bereRegisterOrder>
const mockBereStatus   = bereGetStatus     as jest.MockedFunction<typeof bereGetStatus>

// ─── Setup ────────────────────────────────────────────────────────────────────

const mockPrisma         = mockDeep<PrismaClient>()
const paymentService     = new PaymentService(mockPrisma as unknown as PrismaClient)
const subscriptionService = new SubscriptionService(mockPrisma as unknown as PrismaClient, paymentService)

beforeEach(() => {
  mockReset(mockPrisma)
  jest.clearAllMocks()
})

// ─── Helpers ──────────────────────────────────────────────────────────────────

const userId   = 'user-1'
const planId   = 'plan-monthly'
const orderId  = 'order-1'
const subId    = 'sub-1'
const gwId     = 'gw-123'

const monthlyPlan = {
  id:          planId,
  type:        'monthly' as const,
  name:        'Monthly',
  priceKzt:    2990,
  priceUsd:    9.99,
  durationDays: 30,
  description: 'Full access for 1 month',
  isActive:    true,
  createdAt:   new Date(),
  updatedAt:   new Date(),
}

const annualPlan = {
  ...monthlyPlan,
  id:          'plan-annual',
  type:        'annual' as const,
  name:        'Annual',
  priceKzt:    24990,
  priceUsd:    79.99,
  durationDays: 365,
  description: 'Full access for 1 year — save 30%',
}

function makeSub(overrides: Partial<{
  id: string; userId: string; planId: string; orderId: string | null;
  status: SubscriptionStatus; startedAt: Date | null; expiresAt: Date | null;
}> = {}) {
  const now = new Date()
  return {
    id:        subId,
    userId,
    planId,
    orderId,
    status:    SubscriptionStatus.active,
    startedAt: now,
    expiresAt: new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000),
    createdAt: now,
    updatedAt: now,
    plan:      { type: 'monthly', name: 'Monthly', durationDays: 30 },
    ...overrides,
  }
}

function makeOrder(overrides: Partial<{
  id: string; status: OrderStatus; orderType: OrderType; gateway: PaymentGateway;
  amount: number; currency: string; gatewayOrderId: string | null; paymentUrl: string | null;
}> = {}) {
  return {
    id:            orderId,
    userId,
    status:        OrderStatus.pending,
    orderType:     OrderType.subscription,
    gateway:       PaymentGateway.bereke,
    amount:        2990,
    currency:      'KZT',
    gatewayOrderId: gwId,
    paymentUrl:    'https://pay.bereke/form',
    transactionId: null,
    description:   'Monthly Subscription',
    createdAt:     new Date(),
    updatedAt:     new Date(),
    ...overrides,
  }
}

// ─── getPlans ─────────────────────────────────────────────────────────────────

describe('getPlans', () => {
  it('SUB-1. returns all active subscription plans', async () => {
    mockPrisma.subscriptionPlan.findMany.mockResolvedValue([monthlyPlan, annualPlan] as any)

    const result = await subscriptionService.getPlans()

    expect(result).toHaveLength(2)
    expect(result[0].type).toBe('monthly')
    expect(result[1].type).toBe('annual')
  })
})

// ─── subscribe ────────────────────────────────────────────────────────────────

describe('subscribe', () => {
  it('SUB-2. creates pending subscription and returns Bereke payment URL', async () => {
    mockPrisma.subscriptionPlan.findUnique.mockResolvedValue(monthlyPlan as any)
    mockPrisma.userSubscription.findFirst.mockResolvedValue(null) // no idempotent match
    // paymentService.checkout internals
    mockPrisma.order.findFirst.mockResolvedValue(null)
    mockPrisma.order.create.mockResolvedValue(makeOrder({ status: OrderStatus.created, gatewayOrderId: null, paymentUrl: null }) as any)
    mockBereRegister.mockResolvedValue({ gatewayOrderId: gwId, paymentUrl: 'https://pay.bereke/form' })
    mockPrisma.order.update.mockResolvedValue(makeOrder() as any)
    mockPrisma.userSubscription.create.mockResolvedValue(makeSub({ status: SubscriptionStatus.pending }) as any)

    const result = await subscriptionService.subscribe(userId, { planType: 'monthly', gateway: 'bereke' })

    expect(mockPrisma.userSubscription.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ userId, planId, status: SubscriptionStatus.pending }),
      }),
    )
    expect(result.paymentUrl).toBe('https://pay.bereke/form')
    expect(result.plan.type).toBe('monthly')
    expect(result.idempotent).toBe(false)
  })

  it('SUB-3. uses USD price when gateway is PayPal', async () => {
    mockPrisma.subscriptionPlan.findUnique.mockResolvedValue(monthlyPlan as any)
    mockPrisma.userSubscription.findFirst.mockResolvedValue(null)
    mockPrisma.order.findFirst.mockResolvedValue(null)
    mockPrisma.order.create.mockResolvedValue(makeOrder({ gateway: PaymentGateway.paypal, amount: 9.99, currency: 'USD' }) as any)
    const mockPPCreate = jest.requireMock('../src/services/paypal.service').createPayPalOrder as jest.Mock
    mockPPCreate.mockResolvedValue({ orderId: 'pp-1', approvalUrl: 'https://paypal.com/approve' })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ gateway: PaymentGateway.paypal, amount: 9.99, currency: 'USD' }) as any)
    mockPrisma.userSubscription.create.mockResolvedValue({} as any)

    await subscriptionService.subscribe(userId, { planType: 'monthly', gateway: 'paypal' })

    expect(mockPrisma.order.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ amount: 9.99, currency: 'USD' }) }),
    )
  })

  it('SUB-4. idempotency — returns existing pending subscription within 5 min', async () => {
    mockPrisma.subscriptionPlan.findUnique.mockResolvedValue(monthlyPlan as any)
    mockPrisma.userSubscription.findFirst.mockResolvedValue(makeSub({ status: SubscriptionStatus.pending }) as any)
    mockPrisma.order.findUnique.mockResolvedValue(makeOrder() as any)

    const result = await subscriptionService.subscribe(userId, { planType: 'monthly', gateway: 'bereke' })

    expect(mockBereRegister).not.toHaveBeenCalled()
    expect(result.idempotent).toBe(true)
  })

  it('SUB-5. throws 404 for unknown plan', async () => {
    mockPrisma.subscriptionPlan.findUnique.mockResolvedValue(null)

    await expect(
      subscriptionService.subscribe(userId, { planType: 'monthly', gateway: 'bereke' }),
    ).rejects.toMatchObject({ statusCode: 404, code: 'PLAN_NOT_FOUND' })
  })
})

// ─── getMySubscription ────────────────────────────────────────────────────────

describe('getMySubscription', () => {
  it('SUB-6. returns active subscription with plan details', async () => {
    mockPrisma.userSubscription.findFirst.mockResolvedValue(makeSub() as any)

    const result = await subscriptionService.getMySubscription(userId)

    expect(result).not.toBeNull()
    expect(result!.status).toBe(SubscriptionStatus.active)
    expect(result!.plan.type).toBe('monthly')
  })

  it('SUB-7. returns null when no subscription exists', async () => {
    mockPrisma.userSubscription.findFirst.mockResolvedValue(null)

    const result = await subscriptionService.getMySubscription(userId)

    expect(result).toBeNull()
  })

  it('SUB-8. auto-expires subscription past expiresAt', async () => {
    const expired = makeSub({ expiresAt: new Date('2020-01-01') })
    mockPrisma.userSubscription.findFirst.mockResolvedValue(expired as any)
    mockPrisma.userSubscription.update.mockResolvedValue({ ...expired, status: SubscriptionStatus.expired } as any)

    const result = await subscriptionService.getMySubscription(userId)

    expect(mockPrisma.userSubscription.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { status: SubscriptionStatus.expired } }),
    )
    expect(result!.status).toBe(SubscriptionStatus.expired)
  })
})

// ─── hasActiveSubscription ────────────────────────────────────────────────────

describe('hasActiveSubscription', () => {
  it('SUB-9. returns true when active subscription exists', async () => {
    mockPrisma.userSubscription.findFirst.mockResolvedValue(makeSub() as any)
    expect(await subscriptionService.hasActiveSubscription(userId)).toBe(true)
  })

  it('SUB-10. returns false when no active subscription', async () => {
    mockPrisma.userSubscription.findFirst.mockResolvedValue(null)
    expect(await subscriptionService.hasActiveSubscription(userId)).toBe(false)
  })
})

// ─── cancelSubscription ───────────────────────────────────────────────────────

describe('cancelSubscription', () => {
  it('SUB-11. cancels active subscription and returns expiry date', async () => {
    const sub = makeSub()
    mockPrisma.userSubscription.findFirst.mockResolvedValue(sub as any)
    mockPrisma.userSubscription.update.mockResolvedValue({ ...sub, status: SubscriptionStatus.cancelled } as any)

    const result = await subscriptionService.cancelSubscription(userId)

    expect(mockPrisma.userSubscription.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { status: SubscriptionStatus.cancelled } }),
    )
    expect(result.message).toContain('cancelled')
    expect(result.expiresAt).toBeDefined()
  })

  it('SUB-12. throws 404 when no active subscription to cancel', async () => {
    mockPrisma.userSubscription.findFirst.mockResolvedValue(null)

    await expect(subscriptionService.cancelSubscription(userId)).rejects.toMatchObject({
      statusCode: 404,
      code: 'SUBSCRIPTION_NOT_FOUND',
    })
  })
})

// ─── Payment: activation on subscription order paid ──────────────────────────

describe('activateSubscriptionForOrder (via handleBereSuccess)', () => {
  it('SUB-13. activates subscription when Bereke confirms subscription order paid', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder({ status: OrderStatus.pending }) as any)
    mockBereStatus.mockResolvedValue({ orderStatus: 2, amountKzt: 2990, actionCode: 0 })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.paid }) as any)

    // activateSubscriptionForOrder internals
    mockPrisma.userSubscription.findFirst.mockResolvedValue({
      ...makeSub({ status: SubscriptionStatus.pending, startedAt: null, expiresAt: null }),
      plan: monthlyPlan,
    } as any)
    mockPrisma.$transaction.mockImplementation(async (fn: any) => fn(mockPrisma))
    mockPrisma.userSubscription.updateMany.mockResolvedValue({ count: 0 } as any)
    mockPrisma.userSubscription.update.mockResolvedValue(makeSub() as any)

    const result = await paymentService.handleBereSuccess(gwId)

    expect(mockPrisma.userSubscription.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ status: SubscriptionStatus.active }),
      }),
    )
    expect(result.success).toBe(true)
  })

  it('SUB-14. cancels previous active subscription on new subscription activation', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder({ status: OrderStatus.pending }) as any)
    mockBereStatus.mockResolvedValue({ orderStatus: 2, amountKzt: 2990, actionCode: 0 })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.paid }) as any)
    mockPrisma.userSubscription.findFirst.mockResolvedValue({
      ...makeSub({ status: SubscriptionStatus.pending, startedAt: null, expiresAt: null }),
      plan: monthlyPlan,
    } as any)
    mockPrisma.$transaction.mockImplementation(async (fn: any) => fn(mockPrisma))
    mockPrisma.userSubscription.updateMany.mockResolvedValue({ count: 1 } as any)
    mockPrisma.userSubscription.update.mockResolvedValue(makeSub() as any)

    await paymentService.handleBereSuccess(gwId)

    expect(mockPrisma.userSubscription.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ userId, status: 'active' }),
        data:  { status: 'cancelled' },
      }),
    )
  })
})
