import TagManager from 'react-gtm-module';
import { AppProps } from 'next/app';
import { Auth0Provider, useAuth0 } from '@auth0/auth0-react';
import { config } from '@black-pear-joggers/core-services';
import { Container } from '@black-pear-joggers/container';
import { Footer } from '@black-pear-joggers/footer';
import { Header } from '@black-pear-joggers/header';
import { PropsWithChildren, useEffect } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Stack } from '@black-pear-joggers/stack';
import './styles.css';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
    },
  },
});

const tagManagerArgs = {
  gtmId: 'GTM-W8KBB3D',
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
  const { isLoading, getAccessTokenSilently, loginWithRedirect } = useAuth0();

  useEffect(() => {
    (async () => {
      try {
        localStorage.setItem(
          'bpj.token',
          await getAccessTokenSilently({
            authorizationParams: {
              audience: config.auth().authorizationParams?.audience,
            },
          })
        );
      } catch (e) {
        loginWithRedirect(config.auth());
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
  useEffect(() => {
    TagManager.initialize(tagManagerArgs);
  }, []);

  return (
    <Auth0Provider
      {...config.auth(
        (typeof window !== 'undefined' &&
          `${window.location.origin}/register`) ||
          undefined
      )}
    >
      <QueryClientProvider client={queryClient}>
        <div id="modalContainer"></div>
        <div id="certificate-print-container"></div>
        <PageContent>
          <Component {...pageProps} />
        </PageContent>
      </QueryClientProvider>
    </Auth0Provider>
  );
}

export default CustomApp;
