import { config as sharedConfig } from "@black-pear-joggers/core-services";

export const tagManagerArgs = {
    gtmId: 'GTM-W8KBB3D',
};

export const redirectUri = typeof window !== 'undefined' && `${window.location.origin}/admin`;

export const config = {
    ...sharedConfig,
    auth: sharedConfig.auth(redirectUri),
}