import { UseFormRegisterReturn } from 'react-hook-form';

export interface TimeInputProps {
  id: string;
  label: string;
  defaultValue?: string;
  registerField: UseFormRegisterReturn;
}

export function TimeInput(props: TimeInputProps): JSX.Element {
  return (
    <>
      <fieldset>
        <legend className="block font-bold mb-1">{props.label}</legend>
        <div className="flex flex-wrap -mx-3">
          <div className="w-full md:w-1/2 pl-3">
            <label className="sr-only" htmlFor={`input-${props.id}`}>
              {props.label}
            </label>

            <input
              className="block w-full border rounded py-3 px-4 h-12"
              id={`input-${props.id}`}
              placeholder="Minutes"
              type="number"
              defaultValue={props.defaultValue}
              {...props.registerField}
            />
          </div>
          <div className="w-full md:w-1/2 pl-2 pr-3">
            <label className="sr-only" htmlFor={`input-${props.id}`}>
              {props.label}
            </label>

            <input
              className="block w-full border rounded py-3 px-4 h-12"
              id={`input-${props.id}`}
              placeholder="Seconds"
              type="number"
              defaultValue={props.defaultValue}
              {...props.registerField}
            />
          </div>
        </div>
      </fieldset>
    </>
  );
}
