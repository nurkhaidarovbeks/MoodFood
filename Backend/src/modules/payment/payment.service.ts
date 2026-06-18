import { PrismaClient, OrderStatus, OrderType, PaymentGateway, TransactionType, Order } from '@prisma/client'
import { AppError } from '../../middleware/errorHandler'
import type { CheckoutInput, RefundInput } from './payment.schema'
import { bereRegisterOrder, bereGetStatus, bereRefund } from '../../services/bereke.service'
import { createPayPalOrder, capturePayPalOrder } from '../../services/paypal.service'

// Slide 7 — state machine
export const VALID_TRANSITIONS: Record<OrderStatus, OrderStatus[]> = {
  created:   [OrderStatus.pending,    OrderStatus.cancelled],
  pending:   [OrderStatus.paid,       OrderStatus.failed,  OrderStatus.cancelled],
  paid:      [OrderStatus.fulfilled,  OrderStatus.refunded],
  fulfilled: [OrderStatus.completed,  OrderStatus.refunded],
  failed:    [OrderStatus.pending],
  completed: [],
  refunded:  [],
  cancelled: [],
}

export class PaymentService {
  constructor(private prisma: PrismaClient) {}

  private assertTransition(current: OrderStatus, next: OrderStatus): void {
    if (!VALID_TRANSITIONS[current].includes(next)) {
      throw new AppError(
        400,
        `Invalid status transition: ${current} → ${next}`,
        'INVALID_STATUS_TRANSITION',
      )
    }
  }

  // When a subscription order is paid — atomically activate the subscription
  private async activateSubscriptionForOrder(order: Order): Promise<void> {
    const sub = await this.prisma.userSubscription.findFirst({
      where:   { orderId: order.id },
      include: { plan: true },
    })
    if (!sub) return

    const now       = new Date()
    const expiresAt = new Date(now.getTime() + sub.plan.durationDays * 24 * 60 * 60 * 1000)

    await this.prisma.$transaction(async tx => {
      // Cancel any existing active subscription for this user
      await tx.userSubscription.updateMany({
        where: { userId: order.userId, status: 'active' },
        data:  { status: 'cancelled' },
      })
      // Activate the new one
      await tx.userSubscription.update({
        where: { id: sub.id },
        data:  { status: 'active', startedAt: now, expiresAt },
      })
    })
  }

  // When a topup order is paid — atomically credit the user's wallet
  private async creditWallet(
    userId: string,
    amount: number,
    currency: string,
    orderId: string,
  ): Promise<void> {
    await this.prisma.$transaction(async tx => {
      const wallet = await tx.wallet.upsert({
        where: { userId },
        create: { userId, balance: amount },
        update: { balance: { increment: amount } },
      })
      await tx.walletTransaction.create({
        data: {
          walletId: wallet.id,
          orderId,
          amount,
          currency,
          type: TransactionType.topup,
          description: 'Wallet top-up',
        },
      })
    })
  }

  // PAY-002 + PAY-005: checkout with idempotency guard
  async checkout(userId: string, input: CheckoutInput) {
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000)
    const existing = await this.prisma.order.findFirst({
      where: {
        userId,
        status: OrderStatus.pending,
        amount: input.amount,
        gateway: input.gateway as PaymentGateway,
        orderType: input.orderType as OrderType,
        createdAt: { gte: fiveMinutesAgo },
      },
    })

    if (existing) {
      return {
        orderId: existing.id,
        paymentUrl: existing.paymentUrl,
        status: existing.status,
        idempotent: true,
      }
    }

    const currency = input.gateway === 'paypal' ? 'USD' : 'KZT'

    const order = await this.prisma.order.create({
      data: {
        userId,
        amount: input.amount,
        currency,
        status: OrderStatus.created,
        orderType: input.orderType as OrderType,
        gateway: input.gateway as PaymentGateway,
        description: input.description ?? (input.orderType === 'topup' ? 'Wallet top-up' : 'MoodFood'),
      },
    })

    if (input.gateway === 'bereke') {
      const bereke = await bereRegisterOrder(order.id, input.amount, input.description)
      const updated = await this.prisma.order.update({
        where: { id: order.id },
        data: {
          status: OrderStatus.pending,
          gatewayOrderId: bereke.gatewayOrderId,
          paymentUrl: bereke.paymentUrl,
        },
      })
      return {
        orderId: updated.id,
        paymentUrl: updated.paymentUrl,
        status: updated.status,
        idempotent: false,
      }
    }

    // PayPal
    const paypal = await createPayPalOrder(input.amount)
    const updated = await this.prisma.order.update({
      where: { id: order.id },
      data: {
        status: OrderStatus.pending,
        gatewayOrderId: paypal.orderId,
        paymentUrl: paypal.approvalUrl,
      },
    })
    return {
      orderId: updated.id,
      paymentUrl: updated.paymentUrl,
      status: updated.status,
      idempotent: false,
    }
  }

  // PAY-002: Bereke redirects user here after payment
  async handleBereSuccess(gatewayOrderId: string) {
    const order = await this.prisma.order.findFirst({ where: { gatewayOrderId } })
    if (!order) throw new AppError(404, 'Order not found', 'ORDER_NOT_FOUND')

    // Always verify with Bereke — never trust the redirect alone
    const status = await bereGetStatus(gatewayOrderId)

    if (status.orderStatus === 2) {
      this.assertTransition(order.status, OrderStatus.paid)
      await this.prisma.order.update({
        where: { id: order.id },
        data: { status: OrderStatus.paid },
      })
      if (order.orderType === OrderType.topup) {
        await this.creditWallet(order.userId, order.amount, order.currency, order.id)
      }
      if (order.orderType === OrderType.subscription) {
        await this.activateSubscriptionForOrder(order)
      }
      return { success: true, orderId: order.id, status: 'paid' }
    }

    this.assertTransition(order.status, OrderStatus.failed)
    await this.prisma.order.update({
      where: { id: order.id },
      data: { status: OrderStatus.failed },
    })
    return { success: false, orderId: order.id, status: 'failed', orderStatusCode: status.orderStatus }
  }

  // PAY-002: Bereke redirects user here on cancel/failure
  async handleBereFail(gatewayOrderId: string) {
    const order = await this.prisma.order.findFirst({ where: { gatewayOrderId } })
    if (order?.status === OrderStatus.pending) {
      await this.prisma.order.update({
        where: { id: order.id },
        data: { status: OrderStatus.failed },
      })
    }
    return { success: false, status: 'failed' }
  }

  // PAY-003: Bereke POSTs here when payment status changes (regardless of browser)
  async handleBereCallback(body: {
    mdOrder?: string
    orderNumber?: string
    operation?: string
    status?: string
  }) {
    const { mdOrder: gatewayOrderId, orderNumber, operation, status } = body

    const order = await this.prisma.order.findFirst({
      where: orderNumber ? { id: orderNumber } : { gatewayOrderId },
    })

    if (!order) return { status: 'ok' }

    if (operation === 'deposited' && status === '1' && order.status === OrderStatus.pending) {
      const result = await bereGetStatus(gatewayOrderId!)
      if (result.orderStatus === 2) {
        await this.prisma.order.update({
          where: { id: order.id },
          data: { status: OrderStatus.paid, gatewayOrderId },
        })
        if (order.orderType === OrderType.topup) {
          await this.creditWallet(order.userId, order.amount, order.currency, order.id)
        }
        if (order.orderType === OrderType.subscription) {
          await this.activateSubscriptionForOrder(order)
        }
      }
    } else if (operation === 'reversed') {
      const allowed = VALID_TRANSITIONS[order.status]
      if (allowed.includes(OrderStatus.refunded)) {
        await this.prisma.order.update({
          where: { id: order.id },
          data: { status: OrderStatus.refunded },
        })
      }
    }

    return { status: 'ok' }
  }

  // PAY-006: PayPal redirects user here after approval
  async handlePaypalSuccess(paypalToken: string) {
    const order = await this.prisma.order.findFirst({
      where: { gatewayOrderId: paypalToken },
    })
    if (!order) throw new AppError(404, 'Order not found', 'ORDER_NOT_FOUND')

    const result = await capturePayPalOrder(paypalToken)

    if (result.success) {
      this.assertTransition(order.status, OrderStatus.paid)
      await this.prisma.order.update({
        where: { id: order.id },
        data: { status: OrderStatus.paid, transactionId: result.transactionId },
      })
      if (order.orderType === OrderType.topup) {
        await this.creditWallet(order.userId, order.amount, order.currency, order.id)
      }
      if (order.orderType === OrderType.subscription) {
        await this.activateSubscriptionForOrder(order)
      }
      return { success: true, orderId: order.id, status: 'paid' }
    }

    this.assertTransition(order.status, OrderStatus.failed)
    await this.prisma.order.update({
      where: { id: order.id },
      data: { status: OrderStatus.failed },
    })
    return { success: false, orderId: order.id, status: 'failed' }
  }

  async getUserOrders(userId: string) {
    return this.prisma.order.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        amount: true,
        currency: true,
        status: true,
        orderType: true,
        gateway: true,
        description: true,
        createdAt: true,
        updatedAt: true,
      },
    })
  }

  async getOrder(userId: string, orderId: string) {
    const order = await this.prisma.order.findFirst({
      where: { id: orderId, userId },
    })
    if (!order) throw new AppError(404, 'Order not found', 'ORDER_NOT_FOUND')
    return order
  }

  // L2 (slide 10): admin-only refund via Bereke refund.do
  async refundOrder(orderId: string, input: RefundInput) {
    const order = await this.prisma.order.findUnique({ where: { id: orderId } })
    if (!order) throw new AppError(404, 'Order not found', 'ORDER_NOT_FOUND')

    this.assertTransition(order.status, OrderStatus.refunded)

    if (order.gateway === PaymentGateway.bereke && order.gatewayOrderId) {
      const result = await bereRefund(order.gatewayOrderId, input.amount)
      if (!result.success) throw new AppError(502, 'Bereke refund failed', 'REFUND_FAILED')
    }

    await this.prisma.order.update({
      where: { id: order.id },
      data: { status: OrderStatus.refunded },
    })

    return { message: 'Order refunded successfully', orderId }
  }
}
