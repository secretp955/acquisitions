import logger from "#config/logger.js";
import { getAllUsers, getUserById, updateUser, deleteUser } from "#services/users.service.js";
import { userIdSchema, updateUserSchema } from "#validations/users.validation.js";
import { formatValidationError } from "#utils/format.js";

export const fetchAllUsers = async (req, res, next) => {
    try {
        logger.info('Getting users...');

        const allUsers = await getAllUsers();

        res.json({
            message: 'Successfully retrieved users',
            users: allUsers,
            count: allUsers.length,
        })
    } catch (e) {
        logger.error(e);
        next(e);
    }
}

export const fetchUserById = async (req, res, next) => {
    try {
        // Validate request parameters
        const paramValidation = userIdSchema.safeParse(req.params);
        if (!paramValidation.success) {
            return res.status(400).json({
                error: 'Validation failed',
                detail: formatValidationError(paramValidation.error)
            });
        }

        const { id } = paramValidation.data;
        logger.info(`Getting user by ID: ${id}`);

        const user = await getUserById(id);

        res.json({
            message: 'Successfully retrieved user',
            user: user
        });
    } catch (e) {
        logger.error('Error fetching user by ID', e);
        
        if (e.message === 'User not found') {
            return res.status(404).json({
                error: 'User not found',
                message: 'The requested user does not exist'
            });
        }
        
        next(e);
    }
}

export const updateUserById = async (req, res, next) => {
    try {
        // Validate request parameters
        const paramValidation = userIdSchema.safeParse(req.params);
        if (!paramValidation.success) {
            return res.status(400).json({
                error: 'Validation failed',
                detail: formatValidationError(paramValidation.error)
            });
        }

        // Validate request body
        const bodyValidation = updateUserSchema.safeParse(req.body);
        if (!bodyValidation.success) {
            return res.status(400).json({
                error: 'Validation failed',
                detail: formatValidationError(bodyValidation.error)
            });
        }

        const { id } = paramValidation.data;
        const updates = bodyValidation.data;
        
        // Authorization checks
        const currentUserId = req.user.id;
        const currentUserRole = req.user.role;
        
        // Users can only update their own information
        if (currentUserId !== id && currentUserRole !== 'admin') {
            logger.warn(`User ${req.user.email} attempted to update user ${id} without permission`);
            return res.status(403).json({
                error: 'Forbidden',
                message: 'You can only update your own information'
            });
        }
        
        // Only admins can change user roles
        if (updates.role && currentUserRole !== 'admin') {
            logger.warn(`User ${req.user.email} attempted to change role without admin privileges`);
            return res.status(403).json({
                error: 'Forbidden',
                message: 'Only administrators can change user roles'
            });
        }
        
        logger.info(`Updating user ${id}`);

        const updatedUser = await updateUser(id, updates);

        res.json({
            message: 'User updated successfully',
            user: updatedUser
        });
    } catch (e) {
        logger.error('Error updating user', e);
        
        if (e.message === 'User not found') {
            return res.status(404).json({
                error: 'User not found',
                message: 'The requested user does not exist'
            });
        }
        
        next(e);
    }
}

export const deleteUserById = async (req, res, next) => {
    try {
        // Validate request parameters
        const paramValidation = userIdSchema.safeParse(req.params);
        if (!paramValidation.success) {
            return res.status(400).json({
                error: 'Validation failed',
                detail: formatValidationError(paramValidation.error)
            });
        }

        const { id } = paramValidation.data;
        
        // Authorization checks
        const currentUserId = req.user.id;
        const currentUserRole = req.user.role;
        
        // Users can delete their own account, or admins can delete any account
        if (currentUserId !== id && currentUserRole !== 'admin') {
            logger.warn(`User ${req.user.email} attempted to delete user ${id} without permission`);
            return res.status(403).json({
                error: 'Forbidden',
                message: 'You can only delete your own account or need admin privileges'
            });
        }
        
        logger.info(`Deleting user ${id}`);

        const deletedUser = await deleteUser(id);

        res.json({
            message: 'User deleted successfully',
            user: deletedUser
        });
    } catch (e) {
        logger.error('Error deleting user', e);
        
        if (e.message === 'User not found') {
            return res.status(404).json({
                error: 'User not found',
                message: 'The requested user does not exist'
            });
        }
        
        next(e);
    }
}
