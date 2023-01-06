import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Card } from '@black-pear-joggers/card';
import { Container } from '@black-pear-joggers/container';
import { GetStaticProps } from 'next';
import { toPlainText } from '@black-pear-joggers/helpers';

type ResultsPageProps = {};

export function ResultsPage(props: ResultsPageProps) {
  return (
    <>
      <Stack>
        <Container>
          <h1>Results</h1>
        </Container>
      </Stack>
    </>
  );
}

export const getStaticProps: GetStaticProps = async () => {
  const results = null;

  return {
    props: {
      results,
    },
  };
};

export default ResultsPage;
