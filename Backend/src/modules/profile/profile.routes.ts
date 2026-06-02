import { Router } from 'express'
import prisma from '../../config/database'
import { ProfileService } from './profile.service'
import { ProfileController } from './profile.controller'
import { requireAuth } from '../../middleware/auth'
import { validate } from '../../middleware/validate'
import { ProfileUpsertSchema, ProfilePatchSchema } from './profile.schema'

const router = Router()
const profileService = new ProfileService(prisma)
const profileController = new ProfileController(profileService)

// All profile routes require a valid JWT
router.use(requireAuth)

/**
 * GET /api/v1/profile
 * Get current user's profile and completion status.
 */
router.get('/', (req, res, next) => profileController.getProfile(req, res, next))

/**
 * PUT /api/v1/profile
 * Create or fully replace the nutrition profile.
 */
router.put('/', validate(ProfileUpsertSchema), (req, res, next) =>
  profileController.upsertProfile(req, res, next),
)

/**
 * PATCH /api/v1/profile
 * Partially update the nutrition profile. Unspecified fields are preserved.
 */
router.patch('/', validate(ProfilePatchSchema), (req, res, next) =>
  profileController.patchProfile(req, res, next),
)

export default router
