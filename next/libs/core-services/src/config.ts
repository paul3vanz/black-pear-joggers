import { Auth0ProviderOptions } from '@auth0/auth0-react';

interface Config {
    baseApiUrl: string;
    auth: Auth0ProviderOptions;
}

export const config: Config = {
    baseApiUrl: 'https://bpj.org.uk/api/public/index.php',
    auth: {
        domain: 'blackpearjoggers.us.auth0.com',
        clientId: '30P0GEyOCCjXjTI7VtJeAhYwovaJSKq1',
        audience: 'https://bpj.org.uk',
        useRefreshTokens: true,
    },
}