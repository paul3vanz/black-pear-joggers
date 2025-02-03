import PaymentsTable from '../components/payments-table';
import { Container } from '@black-pear-joggers/container';
import { LoadingSpinner } from '../components/loading-spinner';
import { SearchBar } from '@black-pear-joggers/search-bar';
import { Stack } from '@black-pear-joggers/stack';
import { usePayments } from '@black-pear-joggers/core-services';
import { useState } from 'react';
import { withAuthenticationRequired } from '@auth0/auth0-react';

function PaymentsPage() {
  const { payments, isLoading, isError } = usePayments();
  const [search, setSearch] = useState('');

  return (
    <Stack>
      <Container>
        <h1>Payments</h1>

        <SearchBar search={search} setSearch={setSearch} />

        {isLoading ? (
          <LoadingSpinner />
        ) : (
          payments && <PaymentsTable search={search} payments={payments} />
        )}
      </Container>
    </Stack>
  );
}

export default withAuthenticationRequired(PaymentsPage);
