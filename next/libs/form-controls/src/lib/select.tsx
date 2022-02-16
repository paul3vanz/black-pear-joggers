import { UseFormRegisterReturn } from 'react-hook-form';

export interface SelectOption {
  label: string;
  value?: string;
}

export interface SelectProps {
  id: string;
  label: string;
  defaultValue?: string;
  registerField?: UseFormRegisterReturn;
  options: SelectOption[] | string[];
  onChange?: () => void;
}

export function Select(props: SelectProps): JSX.Element {
  return (
    <>
      <label className="block font-bold mb-1" htmlFor={`input-${props.id}`}>
        {props.label}
      </label>

      <select
        className="block w-full border rounded py-3 px-4 h-12"
        id={`input-${props.id}`}
        defaultValue={props.defaultValue}
        onChange={props.onChange || undefined}
        {...props.registerField}
      >
        {props.options.map((option) => (
          <option
            value={typeof option === 'object' ? option.value : option}
            key={typeof option === 'object' ? option.value : option}
          >
            {typeof option === 'object' ? option.label : option}
          </option>
        ))}
      </select>
    </>
  );
}
