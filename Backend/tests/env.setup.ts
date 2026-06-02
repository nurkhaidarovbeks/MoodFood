/**
 * Sets required environment variables before any module is imported in tests.
 * Listed in jest.config.ts setupFiles (runs before test framework).
 */
process.env['NODE_ENV'] = 'test'
process.env['DATABASE_URL'] = 'postgresql://test:test@localhost:5432/moodfood_test'
process.env['JWT_SECRET'] = 'test-jwt-secret-key-minimum-length-is-32-chars'
process.env['JWT_EXPIRES_IN'] = '1h'
process.env['REQUIRE_EMAIL_VERIFICATION'] = 'false'
process.env['GOOGLE_CLIENT_ID'] = 'test-google-client-id.apps.googleusercontent.com'
process.env['SMTP_HOST'] = ''
process.env['SMTP_USER'] = ''
