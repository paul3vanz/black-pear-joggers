import { AwardClaim, update } from '@black-pear-joggers/core-services';
import { awards, distances } from '../../helpers/enums';
import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { friendlyDate } from '@black-pear-joggers/helpers';
import { Select, TextInput } from '@black-pear-joggers/form-controls';
import { updateAthlete } from '@black-pear-joggers/core-services';
import { useFieldArray, useForm } from 'react-hook-form';
import { useMutation } from '@tanstack/react-query';

interface UpdateClaimRacesFormProps {
  awardClaim: AwardClaim;
}

export function UpdateClaimRacesForm({
  awardClaim,
}: UpdateClaimRacesFormProps) {
  const { register, handleSubmit } = useForm();

  const { mutate, isLoading, isSuccess } = useMutation(
    (updatedFields: Partial<AwardClaim>) => {
      return update(awardClaim.id, updatedFields);
    }
  );

  function onSubmit(updatedFields) {
    mutate(updatedFields);
  }

  return (
    <>
      <pre className="text-xs"></pre>
      <form onSubmit={handleSubmit(onSubmit)} className="w-full">
        {awardClaim.races.map((race, index) => (
          <div key={`races[${index}]`}>
            <h3>#{index + 1}</h3>

            <input
              type="hidden"
              id={`race-id-${index}`}
              defaultValue={race.id}
              {...register(`races[${index}].id`)}
            />

            <input
              type="hidden"
              id={`race-timeParsed-${index}`}
              defaultValue={race.timeParsed}
              {...register(`races[${index}].timeParsed`)}
            />

            <div className="flex flex-wrap -mx-3 mb-3">
              <div className="w-full md:w-1/12 px-3 mb-6 md:mb-0">
                <Select
                  label="Distance"
                  id={`race-distance-${index}`}
                  defaultValue={race.distance}
                  options={distances}
                  registerField={register(`races[${index}].distance`)}
                />
              </div>

              <div className="w-full md:w-2/12 px-3 mb-6 md:mb-0">
                <TextInput
                  id={`race-date-${index}`}
                  label="Date"
                  defaultValue={race.date}
                  registerField={register(`races[${index}].date`)}
                />
              </div>

              <div className="w-full md:w-3/12 px-3">
                <TextInput
                  id={`race-race-${index}`}
                  label="Race"
                  defaultValue={race.race}
                  registerField={register(`races[${index}].race`)}
                />
              </div>

              <div className="w-full md:w-1/12 px-3 mb-6 md:mb-0">
                <label className="block font-bold mb-1" htmlFor="grid-time">
                  Time
                </label>

                <input
                  className="block w-full border rounded py-3 px-4 mb-3"
                  id="grid-time"
                  type="text"
                  defaultValue={race.time}
                />
              </div>

              <div className="w-full md:w-1/12 px-3 mb-6 md:mb-0">
                <Select
                  label="Standard"
                  id={`race-standard-${index}`}
                  defaultValue={awardClaim.award}
                  options={awards}
                  registerField={register(`races[${index}].award`)}
                />
              </div>
            </div>
          </div>
        ))}

        <div className="mb-6">
          <ButtonLightTextDarkBackground
            text="Save"
            onClick={handleSubmit(onSubmit)}
          />
        </div>
      </form>
    </>
  );
}

export default UpdateClaimRacesForm;
