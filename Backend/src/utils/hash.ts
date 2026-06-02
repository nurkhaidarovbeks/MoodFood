import crypto from 'crypto'

export function sha256(value: string): string {
  return crypto.createHash('sha256').update(value).digest('hex')
}

export function generateToken(byteLength: number = 32): string {
  return crypto.randomBytes(byteLength).toString('hex')
}
