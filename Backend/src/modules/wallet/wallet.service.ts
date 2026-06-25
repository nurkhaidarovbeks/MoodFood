import { PrismaClient } from '@prisma/client'
import { AppError } from '../../middleware/errorHandler'

export class WalletService {
  constructor(private prisma: PrismaClient) {}

  async getWallet(userId: string) {
    const wallet = await this.prisma.wallet.findUnique({
      where: { userId },
      include: {
        transactions: {
          orderBy: { createdAt: 'desc' },
          take: 20,
          select: {
            id: true,
            amount: true,
            currency: true,
            type: true,
            description: true,
            createdAt: true,
          },
        },
      },
    })

    if (!wallet) {
      return { balance: 0, currency: 'KZT', transactions: [] }
    }

    return {
      balance: wallet.balance,
      currency: 'KZT',
      transactions: wallet.transactions,
    }
  }

  async getTransactions(userId: string, limit: number, offset: number) {
    const wallet = await this.prisma.wallet.findUnique({ where: { userId } })
    if (!wallet) return { transactions: [], total: 0 }

    const [transactions, total] = await Promise.all([
      this.prisma.walletTransaction.findMany({
        where: { walletId: wallet.id },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
        select: {
          id: true,
          amount: true,
          currency: true,
          type: true,
          description: true,
          orderId: true,
          createdAt: true,
        },
      }),
      this.prisma.walletTransaction.count({ where: { walletId: wallet.id } }),
    ])

    return { transactions, total }
  }

  async getBalance(userId: string): Promise<number> {
    const wallet = await this.prisma.wallet.findUnique({ where: { userId } })
    return wallet?.balance ?? 0
  }

  // Debit wallet — used when user spends balance (e.g. buy premium feature)
  async debitWallet(userId: string, amount: number, description: string): Promise<void> {
    const wallet = await this.prisma.wallet.findUnique({ where: { userId } })
    if (!wallet) throw new AppError(400, 'Wallet not found', 'WALLET_NOT_FOUND')
    if (wallet.balance < amount) throw new AppError(400, 'Insufficient balance', 'INSUFFICIENT_BALANCE')

    await this.prisma.$transaction(async tx => {
      await tx.wallet.update({
        where: { id: wallet.id },
        data: { balance: { decrement: amount } },
      })
      await tx.walletTransaction.create({
        data: {
          walletId: wallet.id,
          amount: -amount,
          currency: 'KZT',
          type: 'payment',
          description,
        },
      })
    })
  }
}
