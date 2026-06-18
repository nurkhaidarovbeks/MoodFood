import { mockDeep, mockReset } from 'jest-mock-extended'
import { PrismaClient, OrderStatus, OrderType, PaymentGateway, TransactionType } from '@prisma/client'
import { WalletService } from '../src/modules/wallet/wallet.service'
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

const mockPrisma        = mockDeep<PrismaClient>()
const walletService     = new WalletService(mockPrisma as unknown as PrismaClient)
const paymentService    = new PaymentService(mockPrisma as unknown as PrismaClient)

beforeEach(() => {
  mockReset(mockPrisma)
  jest.clearAllMocks()
})

// ─── Helpers ──────────────────────────────────────────────────────────────────

const userId   = 'user-1'
const walletId = 'wallet-1'
const orderId  = 'order-1'
const gwId     = 'gw-123'

function makeWallet(balance = 5000) {
  return {
    id:        walletId,
    userId,
    balance,
    createdAt: new Date(),
    updatedAt: new Date(),
  }
}

function makeTx(overrides: Partial<{
  id: string; amount: number; currency: string; type: TransactionType; description: string | null; createdAt: Date
}> = {}) {
  return {
    id:          'tx-1',
    amount:      5000,
    currency:    'KZT',
    type:        TransactionType.topup,
    description: 'Wallet top-up',
    createdAt:   new Date(),
    ...overrides,
  }
}

function makeOrder(overrides: Partial<{
  id: string; userId: string; status: OrderStatus; orderType: OrderType;
  gateway: PaymentGateway; amount: number; currency: string; gatewayOrderId: string | null; paymentUrl: string | null;
  transactionId: string | null; description: string | null; createdAt: Date; updatedAt: Date;
}> = {}) {
  return {
    id:            orderId,
    userId,
    status:        OrderStatus.pending,
    orderType:     OrderType.topup,
    gateway:       PaymentGateway.bereke,
    amount:        5000,
    currency:      'KZT',
    gatewayOrderId: gwId,
    paymentUrl:    'https://pay.bereke/form',
    transactionId: null,
    description:   'Wallet top-up',
    createdAt:     new Date(),
    updatedAt:     new Date(),
    ...overrides,
  }
}

// ─── WalletService: getWallet ─────────────────────────────────────────────────

describe('getWallet', () => {
  it('W1. returns balance and last 20 transactions for existing wallet', async () => {
    mockPrisma.wallet.findUnique.mockResolvedValue({
      ...makeWallet(12500),
      transactions: [makeTx({ amount: 5000 }), makeTx({ id: 'tx-2', amount: 7500 })],
    } as any)

    const result = await walletService.getWallet(userId)

    expect(result.balance).toBe(12500)
    expect(result.transactions).toHaveLength(2)
    expect(result.currency).toBe('KZT')
  })

  it('W2. returns zero balance when wallet does not exist yet', async () => {
    mockPrisma.wallet.findUnique.mockResolvedValue(null)

    const result = await walletService.getWallet(userId)

    expect(result.balance).toBe(0)
    expect(result.transactions).toHaveLength(0)
  })
})

// ─── WalletService: getTransactions ──────────────────────────────────────────

describe('getTransactions', () => {
  it('W3. returns paginated transactions with total count', async () => {
    mockPrisma.wallet.findUnique.mockResolvedValue(makeWallet() as any)
    mockPrisma.walletTransaction.findMany.mockResolvedValue([makeTx()] as any)
    mockPrisma.walletTransaction.count.mockResolvedValue(1)

    const result = await walletService.getTransactions(userId, 20, 0)

    expect(result.transactions).toHaveLength(1)
    expect(result.total).toBe(1)
  })

  it('W4. returns empty list when wallet does not exist', async () => {
    mockPrisma.wallet.findUnique.mockResolvedValue(null)

    const result = await walletService.getTransactions(userId, 20, 0)

    expect(result.transactions).toHaveLength(0)
    expect(result.total).toBe(0)
  })
})

// ─── WalletService: getBalance ────────────────────────────────────────────────

describe('getBalance', () => {
  it('W5. returns current balance', async () => {
    mockPrisma.wallet.findUnique.mockResolvedValue(makeWallet(3300) as any)
    expect(await walletService.getBalance(userId)).toBe(3300)
  })

  it('W6. returns 0 when no wallet exists', async () => {
    mockPrisma.wallet.findUnique.mockResolvedValue(null)
    expect(await walletService.getBalance(userId)).toBe(0)
  })
})

// ─── WalletService: debitWallet ───────────────────────────────────────────────

describe('debitWallet', () => {
  it('W7. debits wallet and creates payment transaction', async () => {
    mockPrisma.wallet.findUnique.mockResolvedValue(makeWallet(5000) as any)
    mockPrisma.$transaction.mockImplementation(async (fn: any) => fn(mockPrisma))
    mockPrisma.wallet.update.mockResolvedValue(makeWallet(4000) as any)
    mockPrisma.walletTransaction.create.mockResolvedValue({} as any)

    await walletService.debitWallet(userId, 1000, 'Premium feature')

    expect(mockPrisma.wallet.update).toHaveBeenCalledWith(
      expect.objectContaining({ data: { balance: { decrement: 1000 } } }),
    )
    expect(mockPrisma.walletTransaction.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ amount: -1000, type: 'payment' }),
      }),
    )
  })

  it('W8. throws 400 when balance is insufficient', async () => {
    mockPrisma.wallet.findUnique.mockResolvedValue(makeWallet(500) as any)

    await expect(walletService.debitWallet(userId, 1000, 'Premium')).rejects.toMatchObject({
      statusCode: 400,
      code: 'INSUFFICIENT_BALANCE',
    })
  })

  it('W9. throws 400 when wallet does not exist', async () => {
    mockPrisma.wallet.findUnique.mockResolvedValue(null)

    await expect(walletService.debitWallet(userId, 1000, 'Premium')).rejects.toMatchObject({
      statusCode: 400,
      code: 'WALLET_NOT_FOUND',
    })
  })
})

// ─── PaymentService: topup checkout ──────────────────────────────────────────

describe('checkout — topup orderType', () => {
  it('W10. creates topup order with orderType=topup and returns payment URL', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(null)
    mockPrisma.order.create.mockResolvedValue(
      makeOrder({ status: OrderStatus.created, gatewayOrderId: null, paymentUrl: null }) as any,
    )
    mockBereRegister.mockResolvedValue({ gatewayOrderId: gwId, paymentUrl: 'https://pay.bereke/form' })
    mockPrisma.order.update.mockResolvedValue(makeOrder() as any)

    const result = await paymentService.checkout(userId, {
      amount: 5000,
      gateway: 'bereke',
      orderType: 'topup',
    })

    expect(mockPrisma.order.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ orderType: OrderType.topup }),
      }),
    )
    expect(result.paymentUrl).toBeTruthy()
    expect(result.idempotent).toBe(false)
  })

  it('W11. idempotency includes orderType in duplicate check', async () => {
    const existing = makeOrder()
    mockPrisma.order.findFirst.mockResolvedValue(existing as any)

    const result = await paymentService.checkout(userId, {
      amount: 5000,
      gateway: 'bereke',
      orderType: 'topup',
    })

    expect(mockBereRegister).not.toHaveBeenCalled()
    expect(result.idempotent).toBe(true)
  })
})

// ─── PaymentService: wallet credited on topup payment ────────────────────────

describe('wallet credit on topup paid', () => {
  it('W12. credits wallet when Bereke confirms topup order paid', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder({ status: OrderStatus.pending }) as any)
    mockBereStatus.mockResolvedValue({ orderStatus: 2, amountKzt: 5000, actionCode: 0 })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.paid }) as any)
    mockPrisma.$transaction.mockImplementation(async (fn: any) => fn(mockPrisma))
    mockPrisma.wallet.upsert.mockResolvedValue(makeWallet(5000) as any)
    mockPrisma.walletTransaction.create.mockResolvedValue({} as any)

    const result = await paymentService.handleBereSuccess(gwId)

    expect(mockPrisma.wallet.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where:  { userId },
        update: { balance: { increment: 5000 } },
      }),
    )
    expect(mockPrisma.walletTransaction.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ amount: 5000, type: TransactionType.topup }),
      }),
    )
    expect(result.success).toBe(true)
  })

  it('W13. does NOT credit wallet for regular purchase order', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(
      makeOrder({ orderType: OrderType.purchase }) as any,
    )
    mockBereStatus.mockResolvedValue({ orderStatus: 2, amountKzt: 5000, actionCode: 0 })
    mockPrisma.order.update.mockResolvedValue(
      makeOrder({ status: OrderStatus.paid, orderType: OrderType.purchase }) as any,
    )

    await paymentService.handleBereSuccess(gwId)

    expect(mockPrisma.wallet.upsert).not.toHaveBeenCalled()
  })

  it('W14. credits wallet via Bereke callback for topup order', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder({ status: OrderStatus.pending }) as any)
    mockBereStatus.mockResolvedValue({ orderStatus: 2, amountKzt: 5000, actionCode: 0 })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.paid }) as any)
    mockPrisma.$transaction.mockImplementation(async (fn: any) => fn(mockPrisma))
    mockPrisma.wallet.upsert.mockResolvedValue(makeWallet(5000) as any)
    mockPrisma.walletTransaction.create.mockResolvedValue({} as any)

    await paymentService.handleBereCallback({
      mdOrder:     gwId,
      orderNumber: orderId,
      operation:   'deposited',
      status:      '1',
    })

    expect(mockPrisma.wallet.upsert).toHaveBeenCalled()
  })
})
