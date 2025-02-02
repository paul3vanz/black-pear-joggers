import { classNames } from '@black-pear-joggers/helpers';
import { getYear } from 'date-fns';
import { useEffect, useState, type JSX } from 'react';

export interface DateInputProps {
  id: string;
  label: string;
  required?: boolean;
  error?: string;
  value?: string;
  showHelp?: boolean;
  onChange: (date: string) => void;
}

export function DateInput(props: DateInputProps): JSX.Element {
  const [day, setDay] = useState<number>();
  const [month, setMonth] = useState<number>();
  const [year, setYear] = useState<number>();

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
        <legend
          className={classNames(
            'block font-bold mb-1',
            props.error && 'text-red-500'
          )}
        >
          {props.label}
        </legend>

        {props.showHelp && (
          <p className="text-gray-500 mb-1">For example, 19 3 1987</p>
        )}

        <div className="flex flex-wrap -mx-3">
          <div className="w-1/4 pl-3">
            <label
              className={classNames(
                'block mb-1',
                props.error && 'text-red-500'
              )}
              htmlFor={`input-day-${props.id}`}
            >
              Day
            </label>

            <input
              className={classNames(
                'block w-full border rounded py-3 px-4 h-12',
                props.error && 'bg-red-100 border-red-500'
              )}
              id={`input-day-${props.id}`}
              min="1"
              max="31"
              step="1"
              value={day || ''}
              required={props.required}
              onChange={(e) => setDay(Number(e.target.value))}
              type="number"
            />
          </div>

          <div className="w-1/4 pl-2">
            <label
              className={classNames(
                'block mb-1',
                props.error && 'text-red-500'
              )}
              htmlFor={`input-month-${props.id}`}
            >
              Month
            </label>

            <input
              className={classNames(
                'block w-full border rounded py-3 px-4 h-12',
                props.error && 'bg-red-100 border-red-500'
              )}
              id={`input-month-${props.id}`}
              min="1"
              max="12"
              step="1"
              value={month || ''}
              required={props.required}
              onChange={(e) => setMonth(Number(e.target.value))}
              type="number"
            />
          </div>

          <div className="w-1/2 pl-2 pr-3">
            <label
              className={classNames(
                'block mb-1',
                props.error && 'text-red-500'
              )}
              htmlFor={`input-seconds-${props.id}`}
            >
              Year
            </label>

            <input
              className={classNames(
                'block w-full border rounded py-3 px-4 h-12',
                props.error && 'bg-red-100 border-red-500'
              )}
              id={`input-seconds-${props.id}`}
              min="1900"
              max={getYear(new Date())}
              step="1"
              value={year || ''}
              required={props.required}
              onChange={(e) => setYear(Number(e.target.value))}
              type="number"
            />
          </div>
        </div>
        {props.error && (
          <div id={`error-${props.id}`} className="mt-1 text-sm text-red-500">
            {props.error}
          </div>
        )}
      </fieldset>
    </>
  );
}
