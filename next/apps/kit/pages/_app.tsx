import { AppProps } from 'next/app';
import { Auth0Provider, useAuth0 } from '@auth0/auth0-react';
import { config } from '@black-pear-joggers/core-services';
import { Container } from '@black-pear-joggers/container';
import { Footer } from '@black-pear-joggers/footer';
import { Header } from '@black-pear-joggers/header';
import { PropsWithChildren, useEffect } from 'react';
import { Stack } from '@black-pear-joggers/stack';
import './styles.css';

let getAccessTokenSilently = null;

export const sec = {
  getAccessTokenSilently: () => getAccessTokenSilently,
  setAccessTokenSilently: (func) => (getAccessTokenSilently = func),
};

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
            audience: config.auth.audience,
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
      {...config.auth}
      redirectUri={
        typeof window !== 'undefined' && `${window.location.origin}/admin`
      }
    >
      <div id="modalContainer"></div>
      <PageContent>
        <Component {...pageProps} />
      </PageContent>
    </Auth0Provider>
  );
}

export default CustomApp;