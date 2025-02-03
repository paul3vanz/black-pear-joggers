import { Athlete } from '@black-pear-joggers/core-services';
import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { friendlyDate } from '@black-pear-joggers/helpers';
import { updateAthlete } from '@black-pear-joggers/core-services';
import { useForm } from 'react-hook-form';

interface UpdateAthleteFormProps {
  athlete: Athlete;
}

function onSubmit(data: any) {
  updateAthlete(data.id, {
    id: data.athleteId,
    athleteId: data.athleteId,
    firstName: data.firstName,
    lastName: data.lastName,
    urn: data.urn,
    gender: data.gender,
    dob: data.dob,
  });
}

export function UpdateAthleteForm({ athlete }: UpdateAthleteFormProps) {
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
              defaultValue={athlete.first_name}
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
              defaultValue={athlete.last_name}
              {...register('lastName')}
            />
          </div>
        </div>

        <div className="flex flex-wrap -mx-3 mb-3">
          <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
            <label className="block font-bold mb-2" htmlFor="athlete-id">
              ID
            </label>

            <input
              className="block w-full border rounded py-3 px-4 mb-3"
              id="athlete-id"
              type="text"
              defaultValue={athlete.id}
              {...register('id')}
            />
          </div>

          <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
            <label
              className="block font-bold mb-2"
              htmlFor="athlete-athlete-id"
            >
              UKA Athlete ID
            </label>

            <input
              className="block w-full border rounded py-3 px-4 mb-3"
              id="athlete-athlete-id"
              type="text"
              defaultValue={athlete.id}
              {...register('athleteId')}
            />
          </div>

          <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
            <label
              className="block font-bold mb-2"
              htmlFor="athlete-athlete-urn"
            >
              UKA URN
            </label>

            <input
              className="block w-full border rounded py-3 px-4 mb-3"
              id="athlete-athlete-urn"
              type="text"
              defaultValue={athlete.urn}
              {...register('urn')}
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
              defaultValue={athlete.gender}
              {...register('gender')}
            />
          </div>

          <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
            <label className="block font-bold mb-2" htmlFor="athlete-dob">
              Date of birth
            </label>

            <input
              className="block w-full border rounded py-3 px-4 mb-3"
              id="athlete-dob"
              type="text"
              defaultValue={athlete.dob}
              {...register('dob')}
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
              disabled
              type="text"
              defaultValue={athlete.category}
              {...register('category')}
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

      <ul className="list-disc list-inside mb-4">
        <li>
          <strong>Created:</strong> {friendlyDate(athlete.created_at)}
        </li>
        <li>
          <strong>Last updated:</strong> {friendlyDate(athlete.updated_at)}
        </li>
      </ul>
    </>
  );
}

export default UpdateAthleteForm;
