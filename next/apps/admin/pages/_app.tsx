import AdminBar from '../components/admin-bar/admin-bar';
import { AppProps } from 'next/app';
import { Auth0Provider, useAuth0 } from '@auth0/auth0-react';
import { config } from '@black-pear-joggers/core-services';
import { Container } from '@black-pear-joggers/container';
import { Footer } from '@black-pear-joggers/footer';
import { Forbidden } from '../components/forbidden';
import { Header } from '@black-pear-joggers/header';
import { isAllowedUser, UserWithRoles } from '../helpers/auth';
import { LoadingSpinner } from '../components/loading-spinner';
import { PropsWithChildren, useEffect, useState } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Stack } from '@black-pear-joggers/stack';
import { useRouter } from 'next/dist/client/router';
import './styles.css';

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

function PageContent(props: PropsWithChildren<{}>) {
  const [isAllowed, setIsAllowed] = useState(false);
  const router = useRouter();
  const { isLoading, user, getAccessTokenSilently } = useAuth0<UserWithRoles>();

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

  useEffect(() => {
    if (!isLoading || !user) {
      return;
    }

    setIsAllowed(isAllowedUser(user));
  }, [isLoading, user, router]);

  return (
    <div className="flex flex-col min-h-screen">
      <Header />

      <AdminBar />

      <main className="flex-1">
        {isLoading ? (
          <LoadingContent />
        ) : !isAllowed ? (
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
  return (
    <Auth0Provider
      {...config.auth}
      redirectUri={
        typeof window !== 'undefined' && `${window.location.origin}/admin`
      }
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
