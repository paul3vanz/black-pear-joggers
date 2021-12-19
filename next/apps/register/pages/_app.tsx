import { AppProps } from 'next/app';
import { Auth0Provider, useAuth0 } from '@auth0/auth0-react';
import { Container } from '@black-pear-joggers/container';
import { Footer } from '@black-pear-joggers/footer';
import { Header } from '@black-pear-joggers/header';
import { PropsWithChildren, useEffect } from 'react';
import { Stack } from '@black-pear-joggers/stack';
import './styles.css';



function LoadingContent() {
  return (
    <Stack>
      <Container>
        <p className="text-center text-2xl">Loading...</p>
      </Container>
    </Stack>
  );
}

function PageContent(props: PropsWithChildren<Record<string, unknown>>) {
  const { isLoading, getAccessTokenSilently } = useAuth0();

  useEffect(() => {
    (async () => {
      try {
        localStorage.setItem(
          'bpj.token',
          await getAccessTokenSilently({
            audience: 'https://bpj.org.uk',
          })
        );
      } catch (e) {
        console.error(e);
      }
    })();
  }, [getAccessTokenSilently]);

  return (
    <div className="flex flex-col min-h-screen">
      <Header />

      <main className="flex-1">
        {isLoading ? <LoadingContent /> : props.children}
      </main>

      <Footer />
    </div>
  );
}

function CustomApp({ Component, pageProps }: AppProps) {
  return (
    <Auth0Provider
      domain="blackpearjoggers.us.auth0.com"
      clientId="30P0GEyOCCjXjTI7VtJeAhYwovaJSKq1"
      audience="https://bpj.org.uk"
      redirectUri={typeof window !== 'undefined' && window.location.origin}
    >
      <div id="modalContainer"></div>
      <PageContent>
        <Component {...pageProps} />
      </PageContent>
    </Auth0Provider>
  );
}

export default CustomApp;
