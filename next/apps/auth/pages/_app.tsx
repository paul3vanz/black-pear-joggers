import { AppProps } from 'next/app';
import Head from 'next/head';
import { Auth0Provider } from '@auth0/auth0-react';

import './styles.css';
import { Favicon } from '@black-pear-joggers/favicon';
import { Header } from '@black-pear-joggers/header';
import { Footer } from '@black-pear-joggers/footer';
import AdminBar from '../components/admin-bar/admin-bar';

function CustomApp({ Component, pageProps }: AppProps) {
  return (
    <Auth0Provider
      domain="blackpearjoggers.us.auth0.com"
      clientId="30P0GEyOCCjXjTI7VtJeAhYwovaJSKq1"
      redirectUri={typeof window !== 'undefined' && window.location.origin}
    >
      <div className="flex flex-col">
        <Header />

        <AdminBar />

        <main>
          <Component {...pageProps} />
        </main>

        <Footer />
      </div>
    </Auth0Provider>
  );
}

export default CustomApp;
