import TagManager from 'react-gtm-module';
import { AppProps } from 'next/app';
import { Auth0Provider } from '@auth0/auth0-react';
import { Container } from '@black-pear-joggers/container';
import { Footer } from '@black-pear-joggers/footer';
import { Header } from '@black-pear-joggers/header';
import { PropsWithChildren, useEffect } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Stack } from '@black-pear-joggers/stack';
import './styles.css';
import { config, tagManagerArgs } from '../helpers/config';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
    },
  },
});

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
  return (
    <div className="flex flex-col min-h-screen">
      <Header />

      <main className="flex-1">{props.children}</main>

      <Footer />
    </div>
  );
}

function CustomApp({ Component, pageProps }: AppProps) {
  useEffect(() => {
    TagManager.initialize(tagManagerArgs);
  }, []);

  return (
    <Auth0Provider {...config.auth}>
      <QueryClientProvider client={queryClient}>
        <div id="modalContainer"></div>
        <PageContent>
          <Component {...pageProps} />
        </PageContent>
      </QueryClientProvider>
    </Auth0Provider>
  );
}

export default CustomApp;
