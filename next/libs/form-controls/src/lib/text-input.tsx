import { classNames } from '@black-pear-joggers/helpers';
import { UseFormRegisterReturn } from 'react-hook-form';

import type { JSX } from "react";

export interface TextInputProps {
  id: string;
  label: string;
  labelHidden?: boolean;
  required?: boolean;
  error?: any;
  defaultValue?: string;
  registerField?: UseFormRegisterReturn;
  onChange?: (event: any) => void;
}

export function TextInput(
  props: TextInputProps & Partial<HTMLInputElement>
): JSX.Element {
  return (
    <>
      <label
        className={classNames(
          'block font-bold mb-1',
          props.error && 'text-red-500',
          props.labelHidden && 'sr-only'
        )}
        htmlFor={`input-${props.id}`}
      >
        {props.label}
      </label>

      <input
        className={classNames(
          'block w-full border rounded py-3 px-4 h-12 text-black',
          props.error && 'bg-red-100 border-red-500',
          props.readOnly && 'bg-gray-200 border-gray-300 cursor-default'
        )}
        id={`input-${props.id}`}
        name={props.id}
        type="text"
        readOnly={props.readOnly}
        placeholder={props.placeholder}
        aria-invalid={props.error && true}
        aria-describedby={props.error && `error-${props.id}`}
        required={props.required}
        defaultValue={props.defaultValue}
        {...props.registerField}
        onChange={props.onChange || undefined}
      />
      {props.error && (
        <div id={`error-${props.id}`} className="mt-1 text-sm text-red-500">
          {props.error}
        </div>
      )}
    </>
  );
}
