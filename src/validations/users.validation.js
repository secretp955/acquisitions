import { z } from 'zod';

export const userIdSchema = z.object({
  id: z.coerce.number().int().positive('User ID must be a positive integer'),
});

export const updateUserSchema = z
  .object({
    name: z
      .string()
      .min(2, 'Name must be at least 2 characters')
      .max(255, 'Name must not exceed 255 characters')
      .trim()
      .optional(),
    email: z
      .email('Invalid email format')
      .max(255, 'Email must not exceed 255 characters')
      .toLowerCase()
      .trim()
      .optional(),
    role: z
      .enum(['user', 'admin'], {
        errorMap: () => ({ message: "Role must be either 'user' or 'admin'" }),
      })
      .optional(),
  })
  .refine(data => Object.keys(data).length > 0, {
    message: 'At least one field must be provided for update',
    path: [],
  });
