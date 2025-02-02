import { Container } from '@black-pear-joggers/container';
import {
  GenderFull,
  Standard,
  useStandards,
  useUser,
} from '@black-pear-joggers/core-services';
import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { useEffect, useState } from 'react';
import { StandardsTable } from './standards-table';

export function CurrentTargets() {
  const { data: userProfile, isLoading: isLoadingUser } = useUser();
  const { standards, isLoading: isLoadingStandards } = useStandards();

  const [currentTargets, setCurrentTargets] = useState<Standard[]>([]);

  useEffect(() => {
    if (standards && userProfile) {
      setCurrentTargets(
        standards.filter(
          (standard) =>
            standard.gender === userProfile.athlete.gender &&
            standard.category === userProfile.athlete.category
        )
      );
    }
  }, [userProfile, standards]);

  return (
    <Stack backgroundColour={BackgroundColour.Dark}>
      <Container>
        <h2>Current targets</h2>

        {isLoadingUser || isLoadingStandards ? (
          <>
            <p>Loading...</p>
          </>
        ) : (
          <>
            <p className="mb-8">
              You are currently in the{' '}
              <strong>
                {
                  GenderFull[
                    userProfile!.athlete.gender as keyof typeof GenderFull
                  ]
                }{' '}
                {userProfile!.athlete.category.replace('SEN', 'Senior')}
              </strong>{' '}
              category. The table below shows all the times for the different
              events and awards.
            </p>

            <div className="mb-6 overflow-auto">
              <StandardsTable
                category={userProfile!.athlete.category}
                gender={userProfile!.athlete.gender}
                standards={currentTargets}
              />
            </div>

            <p>
              <a href="https://apps.bpj.org.uk/club-standards/#targets">
                View all categories
              </a>
            </p>
          </>
        )}
      </Container>
    </Stack>
  );
}
