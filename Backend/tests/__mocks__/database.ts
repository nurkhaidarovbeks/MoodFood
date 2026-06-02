// Mock Prisma client used in all unit tests.
// jest.config.ts moduleNameMapper routes any "config/database" import here,
// so services and test files share the same mock instance automatically.
import { PrismaClient } from '@prisma/client'
import { mockDeep, DeepMockProxy } from 'jest-mock-extended'

const prismaMock = mockDeep<PrismaClient>()

export default prismaMock
export type MockPrismaClient = DeepMockProxy<PrismaClient>
