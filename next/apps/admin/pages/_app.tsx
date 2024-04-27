import AdminBar from '../components/admin-bar/admin-bar';
import TagManager from 'react-gtm-module';
import { AppProps } from 'next/app';
import { Auth0Provider, useAuth0 } from '@auth0/auth0-react';
import { Container } from '@black-pear-joggers/container';
import { Footer } from '@black-pear-joggers/footer';
import { Forbidden } from '../components/forbidden';
import { Header } from '@black-pear-joggers/header';
import { UserWithRoles } from '../helpers/auth';
import { LoadingSpinner } from '../components/loading-spinner';
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
        <div className="flex justify-center">
          <LoadingSpinner />
        </div>
      </Container>
    </Stack>
  );
}

function PageContent(props: PropsWithChildren<Record<string, unknown>>) {
  const {
    isLoading,
    error,
    loginWithRedirect,
    isAuthenticated,
    getAccessTokenSilently,
  } = useAuth0<UserWithRoles>();

  useEffect(() => {
    (async () => {
      try {
        const accessToken = await getAccessTokenSilently({
          authorizationParams: {
            audience: config.auth.authorizationParams.audience,
          },
        });

        if (isAuthenticated) {
          localStorage.setItem('bpj.token', accessToken);
        }
      } catch (e) {
        console.log(e);
        console.log('redirecting');
        loginWithRedirect(config.auth);
      }
    })();
  }, [getAccessTokenSilently, isAuthenticated]);

  useEffect(() => {
    console.log('isAuthenticated', isAuthenticated);
    console.log('isLoading', isLoading);
    console.log('error', error);
  }, [isAuthenticated, isLoading, error]);

  return (
    <div className="flex flex-col min-h-screen">
      <Header />

      <AdminBar />

      <main className="flex-1">
        {isLoading ? (
          <LoadingContent />
        ) : !isAuthenticated ? (
          <Forbidden />
        ) : (
          props.children
        )}
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
      {...config.auth}
    >
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
