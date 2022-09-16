import { allowedRoles } from './enums';
import { User } from '@auth0/auth0-react';

export interface UserWithRoles extends User {
    bpjRoles: string[];
}

export function isAllowedUser(user: UserWithRoles): boolean {
    return user.bpjRoles.some((role) => allowedRoles.includes(role));
}