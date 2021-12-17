import { getYear } from 'date-fns';
import { useEffect, useState } from 'react';
import { UseFormRegisterReturn } from 'react-hook-form';


export interface DateInputProps {
  id: string;
  label: string;
  value?: string;
  registerField: UseFormRegisterReturn;
  onChange: (date: string) => void;
}

export function DateInput(props: DateInputProps): JSX.Element {
  const [day, setDay] = useState<number>();
  const [month, setMonth] = useState<number>();
  const [year, setYear] = useState<number>();
  const [date, setDate] = useState<string>();

  useEffect(() => {
    if (props.value) {
      const dateElements = props.value.split('-');

      setDay(Number(dateElements[2]));
      setMonth(Number(dateElements[1]));
      setYear(Number(dateElements[0]));
    }
  }, [props.value]);

  useEffect(() => {
    props.onChange(
      !year || !month || !day
        ? ''
        : [
            year,
            month?.toString().padStart(2, '0'),
            day?.toString().padStart(2, '0'),
          ].join('-')
    );
  }, [day, month, year]);

  return (
    <>
      <fieldset>
        <legend className="block font-bold mb-1">{props.label}</legend>

        <div className="flex flex-wrap -mx-3">
          <div className="w-full md:w-1/4 pl-3">
            <label className="mb-1 block" htmlFor={`input-day-${props.id}`}>
              Day
            </label>

            <input
              className="block w-full border rounded py-3 px-4 h-12"
              id={`input-day-${props.id}`}
              min="1"
              max="31"
              step="1"
              value={day || ''}
              onChange={(e) => setDay(Number(e.target.value))}
              type="number"
            />
          </div>

          <div className="w-full md:w-1/4 pl-2">
            <label className="mb-1 block" htmlFor={`input-month-${props.id}`}>
              Month
            </label>

            <input
              className="block w-full border rounded py-3 px-4 h-12"
              id={`input-month-${props.id}`}
              min="1"
              max="12"
              step="1"
              value={month || ''}
              onChange={(e) => setMonth(Number(e.target.value))}
              type="number"
            />
          </div>

          <div className="w-full md:w-1/2 pl-2 pr-3">
            <label className="mb-1 block" htmlFor={`input-seconds-${props.id}`}>
              Year
            </label>

            <input
              className="block w-full border rounded py-3 px-4 h-12"
              id={`input-seconds-${props.id}`}
              min="1900"
              max={getYear(new Date())}
              step="1"
              value={year || ''}
              onChange={(e) => setYear(Number(e.target.value))}
              type="number"
            />
          </div>
        </div>
      </fieldset>
    </>
  );
}
