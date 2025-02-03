import Link from 'next/link';
import { archive, useAwardClaims } from '@black-pear-joggers/core-services';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { faChevronCircleLeft } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { LoadingSpinner } from '../../../components/loading-spinner';
import { Stack } from '@black-pear-joggers/stack';
import { useMutation } from '@tanstack/react-query';
import { useRouter } from 'next/dist/client/router';
import { withAuthenticationRequired } from '@auth0/auth0-react';

function AwardClaimDetailsPage() {
  const router = useRouter();
  const { id } = router.query;
  const { awardClaims, isLoading, isError } = useAwardClaims();

  const awardClaim = awardClaims
    ? awardClaims.find((awardClaim) => awardClaim.id === Number(id))
    : null;

  const emailMutation = useMutation(() => {
    return fetch('https://contact.bpj.workers.dev/', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: awardClaim!.email,
        firstName: awardClaim!.firstName,
        award: awardClaim!.award,
        certificateId: awardClaim!.id,
      }),
    });
  });

  if (emailMutation.isLoading) {
    return (
      <Stack>
        <Container>
          <div className="flex justify-center">
            <LoadingSpinner text="Emailing certificate..." />
          </div>
        </Container>
      </Stack>
    );
  }

  if (emailMutation.isError) {
    return (
      <Stack>
        <Container>
          <p>Error email award claim</p>
        </Container>
      </Stack>
    );
  }

  return (
    <>
      <Stack>
        <Container>
          <p className="mb-8">
            <Link href={`/club-standards`}>
              <FontAwesomeIcon
                className="pr-2"
                size="lg"
                icon={faChevronCircleLeft}
              />
              Back to claims
            </Link>
          </p>

          <h1 className="mb-8">Email certificate</h1>

          {emailMutation.isSuccess ? (
            <p className="bg-green-500 text-white font-bold p-6">
              Email sent successfully
            </p>
          ) : (
            <>
              <p>Send the following certificate via email?</p>

              {awardClaim ? (
                <ul className="list-disc pl-5">
                  <li>
                    <strong>Name:</strong> {awardClaim.firstName}{' '}
                    {awardClaim.lastName}
                  </li>
                  <li>
                    <strong>Email:</strong> {awardClaim.email}
                  </li>
                  <li>
                    <strong>Award:</strong> {awardClaim.award}
                  </li>
                  <li>
                    <strong>Certificate ID:</strong> {awardClaim.id}
                  </li>
                </ul>
              ) : null}
            </>
          )}

          <div className="flex mt-6">
            <Button text="Email" onClick={() => emailMutation.mutate()} />

            {/* <div className="pl-4">
              <Button text="Archive" />
            </div> */}
          </div>
        </Container>
      </Stack>
    </>
  );
}

export default withAuthenticationRequired(AwardClaimDetailsPage);
