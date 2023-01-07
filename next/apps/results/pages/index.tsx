import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Card } from '@black-pear-joggers/card';
import { Container } from '@black-pear-joggers/container';
import { GetStaticProps } from 'next';
import { LoadingSpinner } from '../components/loading-spinner';
import { ResultsTable } from '../components/results-table';
import { Select, TextInput } from '@black-pear-joggers/form-controls';
import { useForm } from 'react-hook-form';
import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import {
  AgeCategory,
  Gender,
  getPerformances,
} from '@black-pear-joggers/core-services';

type ResultsPageProps = {};

export function ResultsPage(props: ResultsPageProps) {
  const [isPersonalBest, setIsPersonalBest] = useState<boolean>(false);
  const [category, setCategory] = useState<AgeCategory>(AgeCategory.V40);

  const {
    getValues,
    formState: { errors },
    setValue,
    register,
    handleSubmit,
    watch,
  } = useForm<{
    search: string;
    category: AgeCategory;
    gender: Gender;
    isPersonalBest: boolean;
  }>();

  const formValues = watch();

  const { isLoading, error, data } = useQuery(['races', formValues], () =>
    getPerformances({
      search: formValues.search,
      category: formValues.category,
      gender: formValues.gender,
      isPersonalBest: formValues.isPersonalBest,
      limit: 30,
    }).then((response) => response.json())
  );

  return (
    <>
      <Stack>
        <Container>
          <h1>Results</h1>

          <div className="flex flex-wrap -mx-3 mb-3">
            <div className="w-full md:w-1/2 px-3 mb-6 md:mb-0">
              <Select
                id="gender"
                label="Gender"
                options={[
                  {
                    label: 'All',
                    value: '',
                  },
                  {
                    label: 'Male',
                    value: 'M',
                  },
                  {
                    label: 'Female',
                    value: 'W',
                  },
                ]}
                registerField={register('gender', {
                  required: true,
                })}
              />
            </div>

            <div className="w-full md:w-1/2 px-3 mb-6 md:mb-0">
              <Select
                id="category"
                label="Category"
                options={[
                  {
                    label: 'All',
                    value: '',
                  },
                  ...Object.keys(AgeCategory)
                    .filter((key) => isNaN(Number(key)))
                    .map((key) => ({
                      label: key,
                      value: key,
                    })),
                ]}
                registerField={register('category', {
                  required: true,
                })}
              />
            </div>
          </div>

          {isLoading ? <LoadingSpinner /> : null}

          <ResultsTable results={data?.data} />
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
