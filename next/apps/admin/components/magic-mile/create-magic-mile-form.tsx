import { ageCategories, magicMileLocations } from '../../helpers/enums';
import { Athlete } from '@black-pear-joggers/core-services';
import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { createMagicMileResult } from '@black-pear-joggers/core-services';
import { FormProvider, useForm } from 'react-hook-form';
import { isBefore, parseISO } from 'date-fns';
import { MagicMileResult } from '@black-pear-joggers/core-services';
import { Select } from '@black-pear-joggers/form-controls';
import { shortDate } from '@black-pear-joggers/helpers';
import { TextInput } from '@black-pear-joggers/form-controls';
import { TimeInput } from '@black-pear-joggers/form-controls';
import { useAthletes } from '@black-pear-joggers/core-services';
import { useState } from 'react';

interface CreateMagicMileResultFormProps {
  results: MagicMileResult[];
  magicMileResult?: MagicMileResult;
}

interface FormData {
  athleteId?: number;
  firstName: string;
  lastName: string;
  gender: string;
  category: string;
  date: string;
  location: string;
  predictedTime: number;
  actualTime: number;
}

export function CreateMagicMileResultForm(
  props: CreateMagicMileResultFormProps
) {
  const form = useForm<FormData>();
  let athleteId;
  const { athletes } = useAthletes();
  const [showMembers, setShowMembers] = useState(true);
  const [isLoading, setIsLoading] = useState(false);

  function resetForm() {
    form.setValue('firstName', '');
    form.setValue('lastName', '');
    form.setValue('athleteId', undefined);
    form.setFocus('athleteId');
  }

  function handleAthleteChange(
    athletes: Athlete[],
    e: React.ChangeEvent<HTMLSelectElement>
  ) {
    const athlete = athletes.find(
      (athlete) => athlete.id === Number(e.target.value)
    );

    if (!athlete) {
      return;
    }

    athleteId = athlete.id;

    form.setValue('firstName', athlete.first_name);
    form.setValue('lastName', athlete.last_name);
    form.setValue('gender', athlete.gender);
    form.setValue('category', athlete.category);

    const latestResult =
      getLatestResultByAthleteId(props.results, athlete.id) || 0;

    form.setValue('actualTime', latestResult, {
      shouldDirty: true,
      shouldTouch: true,
      shouldValidate: true,
    });
    form.setValue('predictedTime', latestResult, {
      shouldDirty: true,
      shouldTouch: true,
      shouldValidate: true,
    });
  }

  async function onSubmit(data: any) {
    setIsLoading(true);

    const response = await createMagicMileResult({
      athleteId: Number(data.athleteId),
      firstName: data.firstName,
      lastName: data.lastName,
      gender: data.gender,
      category: data.category,
      date: data.date,
      location: data.location,
      predictedTime: data.predictedTime,
      actualTime: data.actualTime,
    });

    setIsLoading(false);

    if (response.ok) {
      resetForm();
    } else {
      alert(`Error adding result: ${response.statusText}`);
    }
  }

  function getAthleteOptionElements(athletes: Athlete[]) {
    const athleteOptions = athletes
      ? athletes
          .sort((a, b) => {
            return a.first_name.localeCompare(b.first_name);
          })
          .map((athlete) => {
            return {
              value: athlete.id.toString(),
              label: `${athlete.first_name} ${athlete.last_name} (${athlete.category})`,
            };
          })
      : [];

    return [{ value: '', label: '' }].concat(athleteOptions);
  }

  return (
    // @ts-ignore
    <FormProvider {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="w-full max-w-lg">
        <div className="flex flex-wrap -mx-3 mb-3">
          <div className="w-full md:w-1/2 px-3 mb-6 md:mb-0">
            <TextInput
              id="date"
              label="Date"
              //   error={form..isSubmitted && form.errors.date}
              registerField={form.register('date', {
                required: true,
                pattern: /\d{4}-\d{2}-\d{2}/,
                value: shortDate(),
              })}
            />
          </div>

          <div className="w-full md:w-1/2 px-3">
            <Select
              id="location"
              label="Location"
              registerField={form.register('location', {
                required: true,
                value: magicMileLocations[2],
              })}
              options={magicMileLocations.map((location) => ({
                value: `Magic Mile (${location})`,
                label: location,
              }))}
            />
          </div>
        </div>

        {showMembers && athletes && (
          <div className="flex flex-wrap -mx-3 mb-3">
            <div className="w-full px-3 mb-6 md:mb-0">
              <Select
                id="athlete"
                label="Name"
                registerField={form.register('athleteId', {
                  onChange: async (e: React.ChangeEvent<HTMLSelectElement>) => {
                    handleAthleteChange(athletes, e);
                  },
                })}
                options={getAthleteOptionElements(athletes)}
              />
              <div className="mt-2">
                <button
                  className="font-bold underline cursor-pointer"
                  onClick={() => {
                    setShowMembers(false);
                    form.setValue('athleteId', undefined);
                  }}
                >
                  Not a member?
                </button>
              </div>
            </div>
          </div>
        )}

        {!showMembers && (
          <div className="flex flex-wrap -mx-3 mb-3">
            <div className="w-full md:w-1/2 px-3 mb-6 md:mb-0">
              <TextInput
                id="firstName"
                label="First name"
                registerField={form.register('firstName', {
                  required: true,
                })}
              />
            </div>

            <div className="w-full md:w-1/2 px-3">
              <TextInput
                id="lastName"
                label="Last name"
                registerField={form.register('lastName', {
                  required: true,
                })}
              />
            </div>

            <div className="px-3 mt-2">
              <a href="#" onClick={() => setShowMembers(true)}>
                Is a member?
              </a>
            </div>
          </div>
        )}

        <div className="flex flex-wrap -mx-3 mb-3">
          <div className="w-full md:w-1/2 px-3 mb-6 md:mb-0">
            <Select
              id="gender"
              label="Gender"
              registerField={form.register('gender', {
                required: true,
              })}
              options={[
                { label: 'Male', value: 'M' },
                { label: 'Female', value: 'W' },
              ]}
            />
          </div>

          <div className="w-full md:w-1/2 px-3">
            <Select
              id="category"
              label="Category"
              registerField={form.register('category', {
                required: true,
                value: 'SEN',
              })}
              options={ageCategories}
            />
          </div>
        </div>

        <div className="flex flex-wrap -mx-3 mb-3">
          <div className="w-full md:w-1/2 px-3 mb-6 md:mb-0">
            <TimeInput
              id="predictedTime"
              label="Predicted time"
              defaultValue="480"
              registerField={form.register('predictedTime')}
            />
          </div>

          <div className="w-full md:w-1/2 px-3 mb-6 md:mb-0">
            <TimeInput
              id="actualTime"
              label="Actual time"
              defaultValue="479"
              registerField={form.register('actualTime')}
            />
          </div>
        </div>

        <div className="mb-6">
          <ButtonLightTextDarkBackground
            text={isLoading ? 'Saving...' : 'Save'}
            onClick={form.handleSubmit(onSubmit)}
          />
        </div>
      </form>
    </FormProvider>
  );
}

function getLatestResultByAthleteId(
  results: MagicMileResult[],
  athleteId: number
): number | null {
  return results
    ? results
        .filter((result) => result.athleteId === athleteId)
        .sort((a, b) =>
          isBefore(parseISO(a.date), parseISO(b.date)) ? 0 : -1
        )[0]?.actualTime
    : null;
}

export default CreateMagicMileResultForm;
