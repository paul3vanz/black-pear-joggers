import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { DateInput, TextInput } from '@black-pear-joggers/form-controls';
import { FormProvider, useForm } from 'react-hook-form';
import { shortDate } from '@black-pear-joggers/helpers';
import { Stack } from '@black-pear-joggers/stack';

interface RegisterFormProps {
  isLoading: boolean;
  onFormSubmit: (idvDetails: FormData) => void;
}

export interface FormData {
  urn: number;
  dateOfBirth: string;
}

export function RegisterForm(props: RegisterFormProps) {
  const form = useForm<FormData>({
    defaultValues: { dateOfBirth: '1983-02-05', urn: 3127917 },
  });

  return (
    <Stack backgroundColour="light">
      <Container>
        <h2>Your details</h2>
        <FormProvider {...form}>
          <form className="w-full max-w-lg">
            <div className="flex flex-wrap -mx-3 mb-3">
              <div className="w-full md:w-2/3 px-3 mb-6 md:mb-0">
                <DateInput
                  id="dateOfBirthInput"
                  label="Date of birth"
                  showHelp={true}
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
                text={props.isLoading ? 'Checking...' : 'Check'}
                onClick={form.handleSubmit(props.onFormSubmit)}
              />
            </div>
          </form>
        </FormProvider>
      </Container>
    </Stack>
  );
}

export default RegisterForm;
