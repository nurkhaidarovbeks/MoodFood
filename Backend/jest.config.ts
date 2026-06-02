import type { Config } from 'jest'

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  setupFiles: ['<rootDir>/tests/env.setup.ts'],
  moduleNameMapper: {
    // Map any import of config/database to the mock, regardless of relative depth
    '^.*/config/database$': '<rootDir>/tests/__mocks__/database.ts',
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/server.ts',
    '!src/config/database.ts',
  ],
  coverageDirectory: 'coverage',
  testMatch: ['**/*.test.ts'],
  verbose: true,
}

export default config
