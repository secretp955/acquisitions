import express from "express";
import { fetchAllUsers, fetchUserById, updateUserById, deleteUserById } from "#controllers/users.controller.js";
import { authenticateToken, requireRole } from "#middleware/auth.middleware.js";

const router = express.Router();

// Apply authentication middleware to all user routes
router.use(authenticateToken);

// Get all users - requires authentication
router.get('/', fetchAllUsers);

// Get user by ID - requires authentication
router.get('/:id', fetchUserById);

// Update user by ID - requires authentication, users can update own info, admins can update any
router.put('/:id', updateUserById);

// Delete user by ID - requires authentication, users can delete own account, admins can delete any
router.delete('/:id', deleteUserById);

export default router;
