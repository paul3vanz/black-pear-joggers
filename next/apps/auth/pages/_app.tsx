import { AppProps } from 'next/app';
import Head from 'next/head';
import { Auth0Provider } from '@auth0/auth0-react';

import './styles.css';

function CustomApp({ Component, pageProps }: AppProps) {
  return (
    <Auth0Provider
      domain="blackpearjoggers.us.auth0.com"
      clientId="30P0GEyOCCjXjTI7VtJeAhYwovaJSKq1"
      redirectUri={typeof window !== 'undefined' && window.location.origin}
    >
      <h1>Black Pear Joggers</h1>
      <Head>
        <title>Welcome to Black Pear Joggers</title>
      </Head>
      <div className="app">
        <main>
          <Component {...pageProps} />
        </main>
      </div>
    </Auth0Provider>
  );
}

export default CustomApp;
