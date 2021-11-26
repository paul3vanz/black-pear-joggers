import { AppProps } from 'next/app';
import Head from 'next/head';
import { Auth0Provider } from '@auth0/auth0-react';
import Link from 'next/link';

import './styles.css';
import { Favicon } from '@black-pear-joggers/favicon';
import { Header } from '@black-pear-joggers/header';
import { Footer } from '@black-pear-joggers/footer';

function CustomApp({ Component, pageProps }: AppProps) {
  return (
    <Auth0Provider
      domain="blackpearjoggers.us.auth0.com"
      clientId="30P0GEyOCCjXjTI7VtJeAhYwovaJSKq1"
      redirectUri={typeof window !== 'undefined' && window.location.origin}
    >
      <div className="flex flex-col">
        <Head>
          <link
            rel="preconnect"
            href="https://fonts.gstatic.com"
            crossOrigin="anonymous"
          />

          <link
            rel="stylesheet"
            href="https://fonts.googleapis.com/css2?family=Catamaran:wght@400;600;800&amp;display=swap"
          />

          <script
            src="https://kit.fontawesome.com/97736414dd.js"
            crossOrigin="anonymous"
          ></script>
        </Head>
        <Header />

        <ul className="flex justify-around py-4 bg-gray-200">
          <li>
            <Link href="/athletes">
              <a>Athletes</a>
            </Link>
          </li>
          <li>
            <Link href="/club-standards">
              <a>Club standards</a>
            </Link>
          </li>
          <li>
            <Link href="/magic-mile">
              <a>Magic mile</a>
            </Link>
          </li>
          <li>
            <Link href="/members">
              <a>Members</a>
            </Link>
          </li>
          <li>
            <Link href="/tools">
              <a>Tools</a>
            </Link>
          </li>
        </ul>
        <main>
          <Component {...pageProps} />
        </main>
        <Footer />
      </div>
    </Auth0Provider>
  );
}

export default CustomApp;
