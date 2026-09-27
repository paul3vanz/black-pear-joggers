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
import { useState } from 'react';
import { withAuthenticationRequired } from '@auth0/auth0-react';

// Automatic emails are currently broken - set to true to re-enable
const isAutomaticEmailEnabled = false;

function AwardClaimDetailsPage() {
  const router = useRouter();
  const { id } = router.query;
  const { awardClaims, isLoading, isError } = useAwardClaims();
  const [isCopied, setIsCopied] = useState(false);

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
        token: awardClaim!.token,
      }),
    });
  });

  const certificateUrl = awardClaim
    ? `https://bpj.org.uk/claim-award/certificate?id=${awardClaim.id}&token=${awardClaim.token}`
    : '';

  const message = awardClaim
    ? `Hi ${awardClaim.firstName},

Congratulations on achieving your ${awardClaim.award} club standard award! We've checked your times over and it's all approved.

You can view and print your certificate here:

${certificateUrl}

Well done!`
    : '';

  if (isAutomaticEmailEnabled && emailMutation.isLoading) {
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

  if (isAutomaticEmailEnabled && emailMutation.isError) {
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

          {!isAutomaticEmailEnabled ? (
            <>
              <p className="bg-yellow-400 font-bold p-6 mb-6">
                Automatic emails are disabled. Copy the message below and send
                it to the member yourself.
              </p>

              {awardClaim ? (
                <>
                  <ul className="list-disc pl-5 mb-6">
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

                  <textarea
                    className="w-full h-64 p-4 border border-gray-400 font-mono text-sm"
                    readOnly
                    value={message}
                    onFocus={(event) => event.target.select()}
                  />

                  <div className="flex mt-6 items-center">
                    <Button
                      text={isCopied ? 'Copied!' : 'Copy message'}
                      onClick={() => {
                        navigator.clipboard.writeText(message);
                        setIsCopied(true);
                      }}
                    />
                  </div>
                </>
              ) : null}
            </>
          ) : emailMutation.isSuccess ? (
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

          {isAutomaticEmailEnabled ? (
            <div className="flex mt-6">
              <Button text="Email" onClick={() => emailMutation.mutate()} />
            </div>
          ) : null}
        </Container>
      </Stack>
    </>
  );
}

export default withAuthenticationRequired(AwardClaimDetailsPage);
