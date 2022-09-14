import { AwardClaim } from '@black-pear-joggers/core-services';
import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { friendlyDate } from '@black-pear-joggers/helpers';
import { updateAthlete } from '@black-pear-joggers/core-services';
import { useForm } from 'react-hook-form';

interface UpdateClaimRacesFormProps {
  awardClaim: AwardClaim;
}

function onSubmit(data) {
  updateAthlete(data.id, {
    athlete_id: data.athleteId,
    first_name: data.firstName,
    last_name: data.lastName,
    urn: data.urn,
  });
}

export function UpdateClaimRacesForm({
  awardClaim,
}: UpdateClaimRacesFormProps) {
  const { register, handleSubmit } = useForm();

  return (
    <>
      <pre className="text-xs"></pre>
      <form onSubmit={handleSubmit(onSubmit)} className="w-full">
        {awardClaim.races.map((race, index) => (
          <>
            {/* <pre className="text-xs" key={race.id}>
              {JSON.stringify(
                {
                  ...race,
                  createdDate: undefined,
                  updatedDate: undefined,
                  claimId: undefined,
                },
                null,
                '    '
              )}
            </pre> */}

            <h3>#{index + 1}</h3>

            <div className="flex flex-wrap -mx-3 mb-3">
              <div className="w-full md:w-1/12 px-3 mb-6 md:mb-0">
                <label className="block font-bold mb-2" htmlFor="grid-distance">
                  Distance
                </label>

                <input
                  className="block w-full border rounded py-3 px-4 mb-3"
                  id="grid-distance"
                  type="text"
                  defaultValue={race.distance}
                />
              </div>

              <div className="w-full md:w-2/12 px-3 mb-6 md:mb-0">
                <label className="block font-bold mb-2" htmlFor="grid-date">
                  Date
                </label>

                <input
                  className="block w-full border rounded py-3 px-4 mb-3"
                  id="grid-date"
                  type="text"
                  defaultValue={race.date}
                />
              </div>

              <div className="w-full md:w-3/12 px-3">
                <label className="block font-bold mb-2" htmlFor="grid-race">
                  Race
                </label>

                <input
                  className="block w-full border rounded py-3 px-4"
                  id="grid-race"
                  type="text"
                  defaultValue={race.race}
                />
              </div>

              <div className="w-full md:w-1/12 px-3 mb-6 md:mb-0">
                <label className="block font-bold mb-2" htmlFor="grid-time">
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
                <label className="block font-bold mb-2" htmlFor="grid-award">
                  Standard
                </label>

                <input
                  className="block w-full border rounded py-3 px-4 mb-3"
                  id="grid-award"
                  type="text"
                  defaultValue={race.award}
                />
              </div>
            </div>
          </>
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
