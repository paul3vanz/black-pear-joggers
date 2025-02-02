import { classNames } from '@black-pear-joggers/helpers';
import { UseFormRegisterReturn } from 'react-hook-form';

import type { JSX } from "react";

export interface SelectOption {
  label: string;
  value?: string;
  disabled?: boolean;
}

export interface SelectProps {
  id: string;
  label: string;
  labelHidden?: boolean;
  defaultValue?: string;
  registerField?: UseFormRegisterReturn;
  options: SelectOption[] | string[] | Array<string | SelectOption>;
  disabled?: boolean;
  onChange?: (event: any) => void;
}

export function Select(props: SelectProps): JSX.Element {
  return (
    <>
      <label
        className={classNames(
          'block font-bold mb-1',
          props.labelHidden && 'sr-only'
        )}
        htmlFor={`input-${props.id}`}
      >
        {props.label}
      </label>

      <select
        className={classNames(
          'block w-full border rounded py-3 px-4 h-12 text-black',
          props.disabled && 'bg-gray-100'
        )}
        id={`input-${props.id}`}
        name={props.id}
        disabled={props.disabled}
        defaultValue={props.defaultValue}
        onChange={props.onChange || undefined}
        {...props.registerField}
      >
        {props.options.map((option) => (
          <option
            value={typeof option === 'object' ? option.value : option}
            key={typeof option === 'object' ? option.value : option}
            disabled={typeof option === 'object' ? option.disabled : undefined}
          >
            {typeof option === 'object' ? option.label : option}
          </option>
        ))}
      </select>
    </>
  );
}
