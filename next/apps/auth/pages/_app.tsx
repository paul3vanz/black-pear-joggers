import { AppProps } from 'next/app';
import { Auth0Provider, useAuth0 } from '@auth0/auth0-react';

import './styles.css';
// import { Favicon } from '@black-pear-joggers/favicon';
import { Header } from '@black-pear-joggers/header';
import { Footer } from '@black-pear-joggers/footer';
import AdminBar from '../components/admin-bar/admin-bar';
import { PropsWithChildren } from 'react';
import { Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';

function LoadingContent() {
  return (
    <Stack>
      <Container>
        <p className="text-center text-2xl">Loading...</p>
      </Container>
    </Stack>
  );
}

function PageContent(props: PropsWithChildren<{}>) {
  const { isLoading } = useAuth0();
  return (
    <div className="flex flex-col">
      <Header />

      <AdminBar />

      <main>{isLoading ? <LoadingContent /> : props.children}</main>

      <Footer />
    </div>
  );
}

function CustomApp({ Component, pageProps }: AppProps) {
  return (
    <Auth0Provider
      domain="blackpearjoggers.us.auth0.com"
      clientId="30P0GEyOCCjXjTI7VtJeAhYwovaJSKq1"
      redirectUri={typeof window !== 'undefined' && window.location.origin}
    >
      <PageContent>
        <Component {...pageProps} />
      </PageContent>
    </Auth0Provider>
  );
}

export default CustomApp;
