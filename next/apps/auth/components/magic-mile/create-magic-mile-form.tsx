import { useForm } from 'react-hook-form';
import { MagicMileResult } from '../../services/magic-mile.interface';
import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { createMagicMileResult } from '../../services/magic-mile';
import { TextInput } from '../../components/forms/text-input';
import { TimeInput } from '../../components/forms/time-input';
import { Select, SelectOption } from '../../components/forms/select';
import { shortDate } from '@black-pear-joggers/helpers';
import { useAthlete, useAthletes } from '../../services/athletes';
import { useEffect, useState } from 'react';
import { Athlete } from '../../services/athletes.interface';

interface CreateMagicMileResultFormProps {
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

function onSubmit(data) {
  console.log(data);
  return;

  createMagicMileResult({
    athleteId: 0,
    firstName: '',
    lastName: '',
    gender: '',
    category: '',
    date: '',
    location: '',
    predictedTime: '',
    predictedTimeParsed: 0,
    actualTime: '',
    actualTimeParsed: 0,
  });
}

const categories = [
  'U20',
  'U23',
  'SEN',
  'V35',
  'V40',
  'V45',
  'V50',
  'V55',
  'V60',
  'V65',
  'V70',
];

const locations = [
  'Diglis Bridge',
  'Grandstand, Pitchcroft',
  'Nunnery Wood Track',
  'Pitchcroft Reverse',
  'Wainwright Road',
];

export function CreateMagicMileResultForm(
  props: CreateMagicMileResultFormProps
) {
  const {
    register,
    handleSubmit,
    watch,
    setValue,
    formState: { isValid, errors, isSubmitted },
  } = useForm<FormData>();
  let athleteId;
  const { athletes } = useAthletes();
  const { athlete } = useAthlete(athleteId);
  const [showMembers, setShowMembers] = useState(true);

  function handleAthleteChange(setValue, athletes: Athlete[], e: any) {
    const athlete = athletes.find(
      (athlete) => athlete.id === Number(e.target.value)
    );

    athleteId = athlete.id;

    setValue('firstName', athlete.first_name);
    setValue('lastName', athlete.last_name);
    setValue('gender', athlete.gender);
    setValue('category', athlete.category);
  }

  function getAthleteOptionElements(athletes: Athlete[]) {
    return athletes
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
  }

  useEffect(() => {}, [athleteId]);

  return (
    <>
      <form onSubmit={handleSubmit(onSubmit)} className="w-full max-w-lg">
        <div className="flex flex-wrap -mx-3 mb-3">
          <div className="w-full md:w-1/2 px-3 mb-6 md:mb-0">
            <TextInput
              id="date"
              label="Date"
              error={isSubmitted && errors.date}
              registerField={register('date', {
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
              registerField={register('location', {
                required: true,
                value: locations[2],
              })}
              options={locations}
            />
          </div>
        </div>

        {showMembers && (
          <div className="flex flex-wrap -mx-3 mb-3">
            <div className="w-full px-3 mb-6 md:mb-0">
              <Select
                id="athlete"
                label="Name"
                registerField={register('athleteId', {
                  onChange: async (e) => {
                    handleAthleteChange(setValue, athletes, e);
                  },
                })}
                options={getAthleteOptionElements(athletes)}
              />
              <div className="mt-2">
                <a
                  href="#"
                  onClick={() => {
                    setShowMembers(false);
                    setValue('athleteId', null);
                  }}
                >
                  Not a member?
                </a>
              </div>
            </div>
          </div>
        )}

        {true && (
          <div className="flex flex-wrap -mx-3 mb-3">
            <div className="w-full md:w-1/2 px-3 mb-6 md:mb-0">
              <TextInput
                id="firstName"
                label="First name"
                registerField={register('firstName', {
                  required: true,
                })}
              />
            </div>

            <div className="w-full md:w-1/2 px-3">
              <TextInput
                id="lastName"
                label="Last name"
                registerField={register('lastName', {
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
              registerField={register('gender', {
                required: true,
              })}
              options={[
                { label: 'Male', value: 'M' },
                { label: 'Female', value: 'F' },
              ]}
            />
          </div>

          <div className="w-full md:w-1/2 px-3">
            <Select
              id="category"
              label="Category"
              registerField={register('category', {
                required: true,
                value: 'SEN',
              })}
              options={categories}
            />
          </div>
        </div>

        <div className="flex flex-wrap -mx-3 mb-3">
          <div className="w-full md:w-1/2 px-3 mb-6 md:mb-0">
            <TimeInput
              id="predictedTime"
              label="Predicted time"
              registerField={register('predictedTime')}
            />
          </div>

          <div className="w-full md:w-1/2 px-3 mb-6 md:mb-0">
            <TimeInput
              id="actualTime"
              label="Actual time"
              registerField={register('actualTime')}
            />
          </div>
        </div>

        <div className="mb-6">
          <ButtonLightTextDarkBackground
            text="Save"
            onClick={handleSubmit(onSubmit)}
          />
        </div>
      </form>
    </>
  );
}

export default CreateMagicMileResultForm;
