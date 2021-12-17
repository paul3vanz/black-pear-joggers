import { Athlete } from '../../auth/services/athletes.interface';
import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { DateInput, TextInput } from '@black-pear-joggers/form-controls';
import { FormProvider, useForm } from 'react-hook-form';
import { shortDate } from '@black-pear-joggers/helpers';
import { useAthleteIdvCheck } from '../../auth/services/athletes';
import { useEffect, useState } from 'react';


interface RegisterFormProps {
  onIdvCheck: (idvDetails: Athlete) => void;
}

export interface IdvDetails {
  urn: number;
  dateOfBirth: string;
}

export function RegisterForm(props: RegisterFormProps) {
  const form = useForm<IdvDetails>({
    defaultValues: { dateOfBirth: '' },
  });
  const [idvDetails, setIdvDetails] = useState<IdvDetails>();

  const { athlete } = useAthleteIdvCheck(
    idvDetails?.urn,
    idvDetails?.dateOfBirth
  );

  async function onSubmit(data: IdvDetails) {
    console.log('data', data);

    setIdvDetails(data);
  }

  useEffect(() => {
    if (props.onIdvCheck) {
      props.onIdvCheck(athlete);
    }
  }, [athlete]);

  return (
    <FormProvider {...form}>
      <form
        onSubmit={form.handleSubmit(setIdvDetails)}
        className="w-full max-w-lg"
      >
        <div className="flex flex-wrap -mx-3 mb-3">
          <div className="w-full md:w-2/3 px-3 mb-6 md:mb-0">
            <DateInput
              id="dateOfBirthInput"
              label="Date of birth"
              value={form.getValues('dateOfBirth')}
              onChange={(date) => form.setValue('dateOfBirth', date)}
            />

            <input
              id="dateOfBirth"
              type="hidden"
              {...form.register('dateOfBirth', {
                required: true,
                pattern: /\d{4}-\d{2}-\d{2}/,
                value: shortDate(),
              })}
            />
          </div>
        </div>

        <div className="flex flex-wrap -mx-3 mb-6">
          <div className="w-full md:w-2/3 px-3 mb-6 md:mb-0">
            <TextInput
              id="urn"
              label="England Athletics URN"
              registerField={form.register('urn', {
                required: true,
                pattern: /^\d+$/,
              })}
            />
          </div>
        </div>

        <div className="mb-6">
          <ButtonLightTextDarkBackground
            text="Check"
            onClick={form.handleSubmit(onSubmit)}
          />
        </div>
      </form>
    </FormProvider>
  );
}

export default RegisterForm;
