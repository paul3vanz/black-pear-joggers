import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { DateInput, TextInput } from '@black-pear-joggers/form-controls';
import { FormProvider, useForm } from 'react-hook-form';
import { shortDate } from '@black-pear-joggers/helpers';

interface RegisterFormProps {
  isLoading: boolean;
  onFormSubmit: (idvDetails: FormData) => void;
}

export interface FormData {
  urn: number;
  dateOfBirth: string;
}

export function RegisterForm(props: RegisterFormProps) {
  const {
    getValues,
    formState: { errors },
    setValue,
    register,
    handleSubmit,
  } = useForm<FormData>();

  return (
    <Stack backgroundColour={BackgroundColour.Light}>
      <Container>
        <h2>Your details</h2>
        <form className="w-full max-w-lg">
          <div className="flex flex-wrap -mx-3 mb-3">
            <div className="w-full md:w-2/3 px-3 mb-6 md:mb-0">
              <DateInput
                id="dateOfBirthInput"
                label="Date of birth"
                error={
                  errors.dateOfBirth && 'Please enter a valid date of birth'
                }
                required={true}
                showHelp={true}
                value={getValues('dateOfBirth')}
                onChange={(date) => setValue('dateOfBirth', date)}
              />

              <input
                id="dateOfBirth"
                type="hidden"
                {...register('dateOfBirth', {
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
                error={errors.urn && 'Please enter a valid number'}
                required={true}
                registerField={register('urn', {
                  required: true,
                  pattern: /^\d+$/,
                })}
              />
            </div>
          </div>

          <div className="mb-6">
            <ButtonLightTextDarkBackground
              text={props.isLoading ? 'Checking...' : 'Check'}
              onClick={handleSubmit(props.onFormSubmit)}
            />
          </div>
        </form>
      </Container>
    </Stack>
  );
}

export default RegisterForm;
