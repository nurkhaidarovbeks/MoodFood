import { mockDeep, mockReset } from 'jest-mock-extended'
import { PrismaClient, OrderStatus, OrderType, PaymentGateway, TransactionType } from '@prisma/client'
import { WalletService } from '../src/modules/wallet/wallet.service'
import { PaymentService } from '../src/modules/payment/payment.service'

jest.mock('../src/services/paypal.service', () => ({
  createPayPalOrder:  jest.fn(),
  capturePayPalOrder: jest.fn(),
}))

import { createPayPalOrder, capturePayPalOrder } from '../src/services/paypal.service'

const mockPPCreate  = createPayPalOrder  as jest.MockedFunction<typeof createPayPalOrder>
const mockPPCapture = capturePayPalOrder as jest.MockedFunction<typeof capturePayPalOrder>

const mockPrisma     = mockDeep<PrismaClient>()
const walletService  = new WalletService(mockPrisma as unknown as PrismaClient)
const paymentService = new PaymentService(mockPrisma as unknown as PrismaClient)

beforeEach(() => {
  mockReset(mockPrisma)
  jest.clearAllMocks()
})

const userId   = 'user-1'
const walletId = 'wallet-1'
const orderId  = 'order-1'
const ppToken  = 'pp-token-1'

function makeWallet(balance = 5000) {
  return { id: walletId, userId, balance, createdAt: new Date(), updatedAt: new Date() }
}

function makeTx(overrides: Partial<{
  id: string; amount: number; currency: string; type: TransactionType; description: string | null; createdAt: Date
}> = {}) {
  return { id: 'tx-1', amount: 5000, currency: 'USD', type: TransactionType.topup, description: 'Wallet top-up', createdAt: new Date(), ...overrides }
}

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
    orderType:      OrderType.topup,
    gateway:        PaymentGateway.paypal,
    amount:         9.99,
    currency:       'USD',
    gatewayOrderId: ppToken,
    paymentUrl:     'https://paypal.com/approve',
    transactionId:  null,
    description:    'Wallet top-up',
    createdAt:      new Date(),
    updatedAt:      new Date(),
    ...overrides,
  }
}

// ─── WalletService: getWallet ─────────────────────────────────────────────────

describe('getWallet', () => {
  it('W1. returns balance and last 20 transactions for existing wallet', async () => {
    mockPrisma.wallet.findUnique.mockResolvedValue({
      ...makeWallet(12500),
      transactions: [makeTx({ amount: 5 }), makeTx({ id: 'tx-2', amount: 7.5 })],
    } as any)

    const result = await walletService.getWallet(userId)

    expect(result.balance).toBe(12500)
    expect(result.transactions).toHaveLength(2)
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
      expect.objectContaining({ data: expect.objectContaining({ amount: -1000, type: 'payment' }) }),
    )
  })

  it('W8. throws 400 when balance is insufficient', async () => {
    mockPrisma.wallet.findUnique.mockResolvedValue(makeWallet(500) as any)
    await expect(walletService.debitWallet(userId, 1000, 'Premium')).rejects.toMatchObject({
      statusCode: 400, code: 'INSUFFICIENT_BALANCE',
    })
  })

  it('W9. throws 400 when wallet does not exist', async () => {
    mockPrisma.wallet.findUnique.mockResolvedValue(null)
    await expect(walletService.debitWallet(userId, 1000, 'Premium')).rejects.toMatchObject({
      statusCode: 400, code: 'WALLET_NOT_FOUND',
    })
  })
})

// ─── PaymentService: topup checkout via PayPal ────────────────────────────────

describe('checkout — topup orderType', () => {
  it('W10. creates topup order with orderType=topup and returns PayPal URL', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(null)
    mockPrisma.order.create.mockResolvedValue(
      makeOrder({ status: OrderStatus.created, gatewayOrderId: null, paymentUrl: null }) as any,
    )
    mockPPCreate.mockResolvedValue({ orderId: ppToken, approvalUrl: 'https://paypal.com/approve' })
    mockPrisma.order.update.mockResolvedValue(makeOrder() as any)

    const result = await paymentService.checkout(userId, { amount: 9.99, orderType: 'topup' })

    expect(mockPrisma.order.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ orderType: OrderType.topup }) }),
    )
    expect(result.paymentUrl).toBeTruthy()
    expect(result.idempotent).toBe(false)
  })

  it('W11. idempotency — returns existing pending topup order', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder() as any)

    const result = await paymentService.checkout(userId, { amount: 9.99, orderType: 'topup' })

    expect(mockPPCreate).not.toHaveBeenCalled()
    expect(result.idempotent).toBe(true)
  })
})

// ─── wallet credit on topup payment via PayPal ───────────────────────────────

describe('wallet credit on topup paid', () => {
  it('W12. credits wallet when PayPal capture confirms topup order paid', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(makeOrder({ status: OrderStatus.pending }) as any)
    mockPPCapture.mockResolvedValue({ success: true, transactionId: 'txn-abc' })
    mockPrisma.order.update.mockResolvedValue(makeOrder({ status: OrderStatus.paid }) as any)
    mockPrisma.$transaction.mockImplementation(async (fn: any) => fn(mockPrisma))
    mockPrisma.wallet.upsert.mockResolvedValue(makeWallet(9.99) as any)
    mockPrisma.walletTransaction.create.mockResolvedValue({} as any)

    const result = await paymentService.handlePaypalSuccess(ppToken)

    expect(mockPrisma.wallet.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where:  { userId },
        update: { balance: { increment: 9.99 } },
      }),
    )
    expect(mockPrisma.walletTransaction.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ type: TransactionType.topup }) }),
    )
    expect(result.success).toBe(true)
  })

  it('W13. does NOT credit wallet for regular purchase order', async () => {
    mockPrisma.order.findFirst.mockResolvedValue(
      makeOrder({ orderType: OrderType.purchase }) as any,
    )
    mockPPCapture.mockResolvedValue({ success: true, transactionId: 'txn-abc' })
    mockPrisma.order.update.mockResolvedValue(
      makeOrder({ status: OrderStatus.paid, orderType: OrderType.purchase }) as any,
    )

    await paymentService.handlePaypalSuccess(ppToken)

    expect(mockPrisma.wallet.upsert).not.toHaveBeenCalled()
  })
})
