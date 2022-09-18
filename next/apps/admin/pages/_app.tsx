import AdminBar from '../components/admin-bar/admin-bar';
import { AppProps } from 'next/app';
import { Auth0Provider, useAuth0 } from '@auth0/auth0-react';
import { config } from '@black-pear-joggers/core-services';
import { Container } from '@black-pear-joggers/container';
import { Footer } from '@black-pear-joggers/footer';
import { Header } from '@black-pear-joggers/header';
import { isAllowedUser, UserWithRoles } from '../helpers/auth';
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
        <p className="text-center text-2xl">Loading...</p>
      </Container>
    </Stack>
  );
}

function PageContent(props: PropsWithChildren<Record<string, unknown>>) {
  const { isLoading, user, getAccessTokenSilently } = useAuth0<UserWithRoles>();
  const [isAllowed, setIsAllowed] = useState(false);
  const router = useRouter();

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

    if (!isAllowed) {
      router.push('/forbidden');
    }
  }, [user, router]);

  return (
    <div className="flex flex-col min-h-screen">
      <Header />

      <AdminBar />

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
