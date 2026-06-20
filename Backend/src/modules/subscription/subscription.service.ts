import { PrismaClient, SubscriptionStatus } from '@prisma/client'
import { AppError } from '../../middleware/errorHandler'
import { PaymentService } from '../payment/payment.service'
import type { SubscribeInput } from './subscription.schema'

export class SubscriptionService {
  constructor(
    private prisma: PrismaClient,
    private paymentService: PaymentService,
  ) {}

  async getPlans() {
    return this.prisma.subscriptionPlan.findMany({
      where: { isActive: true },
      orderBy: { priceKzt: 'asc' },
      select: {
        id:          true,
        type:        true,
        name:        true,
        priceKzt:    true,
        priceUsd:    true,
        durationDays: true,
        description: true,
      },
    })
  }

  async subscribe(userId: string, input: SubscribeInput) {
    const plan = await this.prisma.subscriptionPlan.findUnique({
      where: { type: input.planType },
    })
    if (!plan || !plan.isActive) {
      throw new AppError(404, 'Subscription plan not found', 'PLAN_NOT_FOUND')
    }

    // Idempotency: return existing pending subscription if within 5 min
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000)
    const existingPending = await this.prisma.userSubscription.findFirst({
      where: {
        userId,
        planId: plan.id,
        status: SubscriptionStatus.pending,
        createdAt: { gte: fiveMinutesAgo },
      },
    })
    if (existingPending?.orderId) {
      const order = await this.prisma.order.findUnique({
        where: { id: existingPending.orderId },
      })
      return {
        orderId:    existingPending.orderId,
        paymentUrl: order?.paymentUrl ?? null,
        plan:       { type: plan.type, name: plan.name },
        idempotent: true,
      }
    }

    const amount = plan.priceUsd

    const checkout = await this.paymentService.checkout(userId, {
      amount,
      gateway:   input.gateway,
      orderType: 'subscription',
      description: `${plan.name} Subscription`,
    })

    // Link pending subscription to the order
    await this.prisma.userSubscription.create({
      data: {
        userId,
        planId:  plan.id,
        orderId: checkout.orderId!,
        status:  SubscriptionStatus.pending,
      },
    })

    return {
      orderId:    checkout.orderId,
      paymentUrl: checkout.paymentUrl,
      plan:       { type: plan.type, name: plan.name },
      idempotent: false,
    }
  }

  async getMySubscription(userId: string) {
    const sub = await this.prisma.userSubscription.findFirst({
      where:   { userId, status: { in: [SubscriptionStatus.active, SubscriptionStatus.cancelled] } },
      orderBy: { createdAt: 'desc' },
      include: { plan: { select: { type: true, name: true, durationDays: true } } },
    })

    if (!sub) return null

    // Auto-expire if expiresAt is in the past
    if (sub.expiresAt && sub.expiresAt < new Date() && sub.status === SubscriptionStatus.active) {
      await this.prisma.userSubscription.update({
        where: { id: sub.id },
        data:  { status: SubscriptionStatus.expired },
      })
      return { ...sub, status: SubscriptionStatus.expired }
    }

    return sub
  }

  async hasActiveSubscription(userId: string): Promise<boolean> {
    const sub = await this.prisma.userSubscription.findFirst({
      where: {
        userId,
        status:    SubscriptionStatus.active,
        expiresAt: { gt: new Date() },
      },
    })
    return !!sub
  }

  async cancelSubscription(userId: string) {
    const sub = await this.prisma.userSubscription.findFirst({
      where: { userId, status: SubscriptionStatus.active },
    })
    if (!sub) {
      throw new AppError(404, 'No active subscription found', 'SUBSCRIPTION_NOT_FOUND')
    }

    await this.prisma.userSubscription.update({
      where: { id: sub.id },
      data:  { status: SubscriptionStatus.cancelled },
    })

    return {
      message:   'Subscription cancelled — access remains until expiry',
      expiresAt: sub.expiresAt,
    }
  }
}
