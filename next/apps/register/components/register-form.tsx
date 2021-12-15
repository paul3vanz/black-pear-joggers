import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { FormProvider, useForm } from 'react-hook-form';
import { isBefore, parseISO } from 'date-fns';
import { Select } from '@black-pear-joggers/form-controls';
import { shortDate, timeFormatted } from '@black-pear-joggers/helpers';
import { TextInput } from '@black-pear-joggers/form-controls';
import { TimeInput } from '@black-pear-joggers/form-controls';
import { useState } from 'react';


interface FormData {
  urn: number;
  dateOfBirth: string;
}

async function onSubmit(data) {}

export function RegisterForm() {
  const form = useForm<FormData>();

  return (
    <FormProvider {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="w-full max-w-lg">
        <div className="flex flex-wrap -mx-3 mb-3">
          <div className="w-full md:w-1/2 px-3 mb-6 md:mb-0">
            <TextInput
              id="dateOfBirth"
              label="Date of birth"
              registerField={form.register('dateOfBirth', {
                required: true,
                pattern: /\d{4}-\d{2}-\d{2}/,
                value: shortDate(),
              })}
            />
          </div>
        </div>

        <div className="flex flex-wrap -mx-3 mb-6">
          <div className="w-full md:w-1/2 px-3 mb-6 md:mb-0">
            <TextInput
              id="urn"
              label="England Athletics URN"
              registerField={form.register('urn', {
                required: true,
                pattern: /\d*/,
              })}
            />
          </div>
        </div>

        <div className="mb-6">
          <ButtonLightTextDarkBackground
            text="Save"
            onClick={form.handleSubmit(onSubmit)}
          />
        </div>
      </form>
    </FormProvider>
  );
}

export default RegisterForm;
