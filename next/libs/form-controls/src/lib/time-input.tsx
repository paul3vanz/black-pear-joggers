import { useEffect, useRef, useState, type JSX } from 'react';
import {
  UseFormRegisterReturn,
  useFormContext,
  useWatch,
} from 'react-hook-form';

export interface TimeInputProps {
  id: string;
  label: string;
  defaultValue?: string;
  registerField: UseFormRegisterReturn;
}

export function TimeInput(props: TimeInputProps): JSX.Element {
  const [seconds, setSeconds] = useState<number>();
  const [minutes, setMinutes] = useState<number>();
  const { getValues, setValue, control, watch } = useFormContext();
  const watchTime = watch(props.id, 0);

  const elements = {
    minutes: useRef<HTMLInputElement>(null),
    seconds: useRef<HTMLInputElement>(null),
  };

  // @ts-ignore
  const time = useWatch({
    control,
    name: props.id,
    defaultValue: 0,
  });

  useEffect(() => {
    if (!watchTime) {
      return;
    }

    const minutes = Math.floor(watchTime / 60);
    const seconds = Math.floor(watchTime % 60);

    setMinutes(minutes);
    setSeconds(seconds);
  }, [watchTime]);

  useEffect(() => {
    const timeInSeconds = (minutes ? minutes * 60 : 0) + (seconds || 0);

    if (timeInSeconds !== watchTime) {
      setValue(props.id, timeInSeconds, {
        shouldDirty: false,
        shouldTouch: false,
        shouldValidate: false,
      });
    }
  }, [minutes, seconds]);

  return (
    <>
      <fieldset>
        <legend className="block font-bold mb-1">{props.label}</legend>
        <div className="flex flex-wrap -mx-3">
          <div className="w-1/2 pl-3">
            <label className="mb-1" htmlFor={`input-minutes-${props.id}`}>
              Minutes
            </label>

            <input
              className="block w-full border rounded py-3 px-4 h-12"
              id={`input-minutes-${props.id}`}
              min="0"
              max="59"
              step="1"
              onChange={(e) => setMinutes(Number(e.target.value))}
              value={minutes || '0'}
              type="number"
            />
          </div>

          <div className="w-1/2 pl-2 pr-3">
            <label className="mb-1" htmlFor={`input-seconds-${props.id}`}>
              Seconds
            </label>

            <input
              className="block w-full border rounded py-3 px-4 h-12"
              id={`input-seconds-${props.id}`}
              min="0"
              max="59"
              step="1"
              onChange={(e) => setSeconds(Number(e.target.value))}
              value={seconds || '0'}
              type="number"
            />
          </div>

          <input
            className="block w-full border rounded py-3 px-4 h-12 mx-3 mt-2"
            type="hidden"
            id={`input-${props.id}`}
            defaultValue={props.defaultValue}
            {...props.registerField}
          />
          {}
        </div>
      </fieldset>
    </>
  );
}
