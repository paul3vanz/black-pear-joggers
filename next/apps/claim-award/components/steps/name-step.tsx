import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { TextInput } from '@black-pear-joggers/form-controls';
import { useForm } from 'react-hook-form';

export interface NameStepProps {
  isLoading: boolean;
  onNext: (e: NameStepFormData) => void;
}

export interface NameStepFormData {
  firstName: string;
  lastName: string;
}

export function NameStep(props: NameStepProps) {
  const {
    getValues,
    formState: { errors },
    setValue,
    register,
    handleSubmit,
  } = useForm<NameStepFormData>();

  return (
    <Stack backgroundColour={BackgroundColour.Light}>
      <Container>
        <h2>Your name</h2>

        <form className="w-full max-w-lg">
          <div className="flex flex-wrap -mx-3 mb-6">
            <div className="w-full md:w-2/3 px-3 mb-6 md:mb-0">
              <TextInput
                id="firstName"
                label="First name"
                error={errors.firstName && 'Please enter your first name'}
                required={true}
                registerField={register('firstName', {
                  value: 'Paul',
                  required: true,
                })}
              />
            </div>
          </div>

          <div className="flex flex-wrap -mx-3 mb-6">
            <div className="w-full md:w-2/3 px-3 mb-6 md:mb-0">
              <TextInput
                id="lastName"
                label="Last name"
                error={errors.lastName && 'Please enter your last name'}
                required={true}
                registerField={register('lastName', {
                  value: 'Evans',
                  required: true,
                })}
              />
            </div>
          </div>

          <div className="mb-6">
            <Button
              text={props.isLoading ? 'Checking...' : 'Next'}
              onClick={handleSubmit(props.onNext)}
            />
          </div>
        </form>
      </Container>
    </Stack>
  );
}
