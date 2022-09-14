import { AwardClaim } from '@black-pear-joggers/core-services';
import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { friendlyDate } from '@black-pear-joggers/helpers';
import { updateAthlete } from '@black-pear-joggers/core-services';
import { useForm } from 'react-hook-form';

interface UpdateClaimFormProps {
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

export function UpdateClaimForm({ awardClaim }: UpdateClaimFormProps) {
  const { register, handleSubmit } = useForm();

  return (
    <>
      <form onSubmit={handleSubmit(onSubmit)} className="w-full max-w-lg">
        <div className="flex flex-wrap -mx-3 mb-3">
          <div className="w-full md:w-1/2 px-3 mb-6 md:mb-0">
            <label className="block font-bold mb-2" htmlFor="grid-first-name">
              First name
            </label>

            <input
              className="block w-full border rounded py-3 px-4 mb-3"
              id="grid-first-name"
              type="text"
              defaultValue={awardClaim.firstName}
              {...register('firstName')}
            />
          </div>

          <div className="w-full md:w-1/2 px-3">
            <label className="block font-bold mb-2" htmlFor="grid-last-name">
              Last name
            </label>

            <input
              className="block w-full border rounded py-3 px-4"
              id="grid-last-name"
              type="text"
              defaultValue={awardClaim.lastName}
              {...register('lastName')}
            />
          </div>
        </div>

        <div className="flex flex-wrap -mx-3 mb-3">
          <div className="w-full md:w-1/4 px-3 mb-6 md:mb-0">
            <label className="block font-bold mb-2" htmlFor="athlete-id">
              Athlete ID
            </label>

            <input
              className="block w-full border rounded py-3 px-4 mb-3"
              id="athlete-id"
              type="text"
              defaultValue={awardClaim.athleteId}
              {...register('athleteId')}
            />
          </div>

          <div className="w-full md:w-3/4 px-3 mb-6 md:mb-0">
            <label className="block font-bold mb-2" htmlFor="athlete-email">
              Email address
            </label>

            <input
              className="block w-full border rounded py-3 px-4 mb-3"
              id="athlete-email"
              type="text"
              defaultValue={awardClaim.email}
              {...register('email')}
            />
          </div>
        </div>

        <div className="flex flex-wrap -mx-3 mb-3">
          <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
            <label className="block font-bold mb-2" htmlFor="athlete-gender">
              Gender
            </label>

            <input
              className="block w-full border rounded py-3 px-4 mb-3"
              id="athlete-gender"
              type="text"
              defaultValue={awardClaim.gender}
              {...register('gender')}
            />
          </div>

          <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
            <label
              className="block font-bold mb-2"
              htmlFor="athlete-athlete-category"
            >
              Category
            </label>

            <input
              className="block w-full border rounded py-3 px-4 mb-3"
              id="athlete-athlete-category"
              type="text"
              defaultValue={awardClaim.category}
              {...register('category')}
            />
          </div>

          <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
            <label className="block font-bold mb-2" htmlFor="athlete-award">
              Award
            </label>

            <input
              className="block w-full border rounded py-3 px-4 mb-3"
              id="athlete-award"
              type="text"
              defaultValue={awardClaim.award}
              {...register('award')}
            />
          </div>
        </div>

        <div className="mb-6">
          <ButtonLightTextDarkBackground
            text="Save"
            onClick={handleSubmit(onSubmit)}
          />
        </div>
      </form>

      {/* <ul className="list-disc list-inside mb-4">
        <li>
          <strong>Created:</strong> {friendlyDate(awardClaim.createdDate)}
        </li>
        <li>
          <strong>Last updated:</strong> {friendlyDate(awardClaim.updatedDate)}
        </li>
      </ul> */}
    </>
  );
}

export default UpdateClaimForm;
