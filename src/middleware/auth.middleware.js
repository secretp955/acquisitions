import { jwttoken } from "#utils/jwt.js";
import logger from "#config/logger.js";

export const authenticateToken = async (req, res, next) => {
    try {
        const token = req.cookies?.token;

        if (!token) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'Access token is required'
            });
        }

        const decoded = jwttoken.verify(token);
        req.user = decoded;
        
        logger.info(`User ${decoded.email} authenticated successfully`);
        next();
    } catch (e) {
        logger.error('Authentication error', e);
        return res.status(401).json({
            error: 'Unauthorized',
            message: 'Invalid or expired token'
        });
    }
};

export const requireRole = (requiredRole) => {
    return (req, res, next) => {
        if (!req.user) {
            return res.status(401).json({
                error: 'Unauthorized',
                message: 'Authentication required'
            });
        }

        if (req.user.role !== requiredRole) {
            logger.warn(`Access denied for user ${req.user.email}. Required role: ${requiredRole}, User role: ${req.user.role}`);
            return res.status(403).json({
                error: 'Forbidden',
                message: 'Insufficient permissions'
            });
        }

        next();
    };
};