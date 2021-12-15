import { UseFormRegisterReturn } from 'react-hook-form';

export interface TextInputProps {
  id: string;
  label: string;
  error?: any;
  defaultValue?: string;
  registerField: UseFormRegisterReturn;
}

export function TextInput(props: TextInputProps): JSX.Element {
  return (
    <>
      <label
        className={
          'block font-bold mb-1' + (props.error ? ' text-red-500' : '')
        }
        htmlFor={`input-${props.id}`}
      >
        {props.label}
      </label>

      <input
        className={
          'block w-full border rounded py-3 px-4 h-12' +
          (props.error ? ' bg-red-100' : '')
        }
        id={`input-${props.id}`}
        type="text"
        defaultValue={props.defaultValue}
        {...props.registerField}
      />
    </>
  );
}
