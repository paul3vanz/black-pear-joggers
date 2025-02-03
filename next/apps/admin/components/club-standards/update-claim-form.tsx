import { ageCategories, awards } from '../../helpers/enums';
import { AwardClaim, update } from '@black-pear-joggers/core-services';
import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { Select } from '@black-pear-joggers/form-controls';
import { useForm } from 'react-hook-form';
import { useMutation } from '@tanstack/react-query';

interface UpdateClaimFormProps {
  awardClaim: AwardClaim;
}

export function UpdateClaimForm({ awardClaim }: UpdateClaimFormProps) {
  const { register, handleSubmit } = useForm();

  const { mutate, isLoading, isSuccess } = useMutation(
    (updatedFields: Partial<AwardClaim>) => {
      return update(awardClaim.id, updatedFields);
    }
  );

  function onSubmit(updatedFields: any) {
    mutate(updatedFields);
  }

  return (
    <>
      <form onSubmit={handleSubmit(onSubmit)} className="w-full max-w-lg">
        <div className="flex flex-wrap -mx-3 mb-3">
          <div className="w-full md:w-1/2 px-3 mb-6 md:mb-0">
            <label className="block font-bold mb-1" htmlFor="grid-first-name">
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
            <label className="block font-bold mb-1" htmlFor="grid-last-name">
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
            <label className="block font-bold mb-1" htmlFor="athlete-id">
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
            <label className="block font-bold mb-1" htmlFor="athlete-email">
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
            <Select
              label="Gender"
              id="athlete-gender"
              defaultValue={awardClaim.gender}
              options={[
                { label: 'Female', value: 'W' },
                { label: 'Male', value: 'M' },
              ]}
              registerField={register('gender')}
            />
          </div>

          <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
            <Select
              label="Category"
              id="athlete-category"
              defaultValue={awardClaim.category}
              options={ageCategories}
              registerField={register('category')}
            />
          </div>

          <div className="w-full md:w-1/3 px-3 mb-6 md:mb-0">
            <Select
              label="Award"
              id="athlete-award"
              defaultValue={awardClaim.award}
              options={awards}
              registerField={register('award')}
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
