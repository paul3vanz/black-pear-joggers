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
  eventDistances,
  Gender,
  getPerformances,
  PerformanceFilters,
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
  } = useForm<PerformanceFilters>({
    defaultValues: {
      sort: 'time',
    },
  });

  const formValues = watch();

  const { isLoading, error, data } = useQuery(['races', formValues], () =>
    getPerformances({
      search: formValues.search,
      category: formValues.category,
      gender: formValues.gender,
      isPersonalBest: formValues.isPersonalBest,
      distance: formValues.distance,
      limit: 30,
      page: formValues.page,
      year: formValues.year,
      sort: formValues.sort,
    }).then((response) => response.json())
  );

  return (
    <>
      <Stack>
        <Container wide={true}>
          <h1>Results</h1>

          <div className="flex flex-wrap -mx-3 mb-3">
            <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
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

            <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
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

            <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
              <Select
                id="year"
                label="Year"
                options={[
                  {
                    label: 'Any year',
                    value: '',
                  },
                  '2023',
                  '2022',
                  '2021',
                  '2020',
                  '2019',
                  '2018',
                  '2017',
                  '2016',
                  '2015',
                  '2014',
                  '2013',
                  '2012',
                  '2011',
                  '2010',
                  '2009',
                  '2008',
                  '2007',
                  '2006',
                  '2005',
                  '2004',
                  '2003',
                ]}
                registerField={register('year', {
                  required: true,
                })}
              />
            </div>
          </div>

          <div className="flex flex-wrap -mx-3 mb-6">
            <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
              <Select
                id="isPersonalBest"
                label="Personal bests"
                options={[
                  {
                    label: 'Any results',
                    value: '',
                  },
                  {
                    label: 'Just personal bests',
                    value: '1',
                  },
                ]}
                registerField={register('isPersonalBest', {
                  required: true,
                })}
              />
            </div>

            <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
              <Select
                id="distance"
                label="Distance"
                options={[
                  {
                    label: 'Any distance',
                    value: '',
                  },
                  ...eventDistances.map((event) => ({
                    label: event.event.toString(),
                    value: event.distance.toString(),
                  })),
                ]}
                registerField={register('distance', {
                  required: true,
                })}
              />
            </div>

            <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
              <Select
                id="sort"
                label="Sort"
                options={[
                  {
                    label: 'Finish time',
                    value: 'time',
                  },
                  {
                    label: 'Date',
                    value: 'date',
                  },
                ]}
                registerField={register('sort', {
                  required: true,
                })}
              />
            </div>
          </div>

          {isLoading ? <LoadingSpinner /> : null}

          {data?.data ? (
            <>
              <div className="mb-4">
                <ResultsTable results={data?.data} />
              </div>

              <Select
                id="page"
                label={`Page ${data?.current_page} of ${data?.last_page}`}
                options={[...Array(data?.last_page).keys()].map((i) =>
                  (i + 1).toString()
                )}
                registerField={register('page', {
                  required: true,
                })}
              />
            </>
          ) : null}
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
