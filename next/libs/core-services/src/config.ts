import { Auth0ProviderOptions } from '@auth0/auth0-react';

interface Config {
    baseApiUrl: string;
    auth: (redirectUri?: string) => Auth0ProviderOptions;
}

export const config: Config = {
    baseApiUrl: 'https://bpj.org.uk/api/public/index.php',
    // baseApiUrl: 'http://localhost:8000',
    auth: (redirectUri?: string) => ({
        domain: 'blackpearjoggers.us.auth0.com',
        clientId: '30P0GEyOCCjXjTI7VtJeAhYwovaJSKq1',
        authorizationParams: {
            audience: 'https://bpj.org.uk',
            redirect_uri: redirectUri || undefined,
        },
        useRefreshTokens: true,
        useRefreshTokensFallback: true,
    }),
}