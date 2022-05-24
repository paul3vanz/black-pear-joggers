import { classNames } from '@black-pear-joggers/helpers';
import { UseFormRegisterReturn } from 'react-hook-form';

export interface TextAreaProps {
  id: string;
  label: string;
  required?: boolean;
  error?: any;
  defaultValue?: string;
  registerField?: UseFormRegisterReturn;
  onChange?: (event: any) => void;
}

export function TextArea(props: TextAreaProps): JSX.Element {
  return (
    <>
      <label
        className={classNames(
          'block font-bold mb-1',
          props.error && 'text-red-500'
        )}
        htmlFor={`input-${props.id}`}
      >
        {props.label}
      </label>

      <textarea
        className={classNames(
          'block w-full border rounded py-3 px-4 h-48',
          props.error && 'bg-red-100 border-red-500'
        )}
        id={`input-${props.id}`}
        name={props.id}
        aria-invalid={props.error && true}
        aria-describedby={props.error && `error-${props.id}`}
        required={props.required}
        defaultValue={props.defaultValue}
        {...props.registerField}
        onChange={props.onChange || undefined}
      ></textarea>
      {props.error && (
        <div id={`error-${props.id}`} className="mt-1 text-sm text-red-500">
          {props.error}
        </div>
      )}
    </>
  );
}
