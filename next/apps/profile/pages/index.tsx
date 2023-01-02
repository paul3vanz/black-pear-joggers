import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { useAuth0 } from '@auth0/auth0-react';
import { useUser } from '@black-pear-joggers/core-services';

export default function ProfilePage() {
  const { user, logout } = useAuth0();
  const { data: userProfile } = useUser();

  return (
    <>
      <Stack backgroundColour={BackgroundColour.Bright}>
        <Container>
          <p className="text-xl font-bold mb-2">
            This area is currently under construction.
          </p>
          <p>More features will appear here soon.</p>
        </Container>
      </Stack>

      <Stack>
        <Container>
          <h1>Profile</h1>

          <p>
            You&rsquo;re currently logged in as <strong>{user?.email}</strong>.
          </p>

          {userProfile?.athleteId ? (
            <>
              <h2>Your details</h2>

              <p>
                You&rsquo;ve linked your membership details to your account. If
                you&rsquo;d like to update your details, please{' '}
                <a href="https://bpj.org.uk/contact?reason=website">
                  contact us
                </a>
                .
              </p>

              <ul className="mb-6 list-inside list-disc">
                <li>
                  <strong>First name:</strong> {userProfile.athlete.first_name}
                </li>
                <li>
                  <strong>Last name:</strong> {userProfile.athlete.last_name}
                </li>
                <li>
                  <strong>Gender:</strong>{' '}
                  {userProfile.athlete.gender === 'M' ? 'Male' : 'Female'}
                </li>
                <li>
                  <strong>Category:</strong> {userProfile.athlete.category}
                </li>
                <li>
                  <strong>Athlete ID:</strong> {userProfile.athlete.athlete_id}
                </li>
              </ul>

              <h2>Useful links</h2>

              <ul className="mb-6 list-inside list-disc">
                <li>
                  <a
                    href={`https://apps.bpj.org.uk/race-results/#/athlete/${userProfile?.athleteId}`}
                  >
                    Your race results and rankings
                  </a>
                </li>
                <li>
                  <a
                    href={`https://www.thepowerof10.info/athletes/profile.aspx?athleteid=${userProfile?.athleteId}`}
                  >
                    Your Power of 10 profile
                  </a>
                </li>
                <li>
                  <a
                    href={`https://www.runbritainrankings.com/runners/profile.aspx?athleteid=${userProfile?.athleteId}`}
                  >
                    Your runbritain Rankings profile
                  </a>
                </li>
              </ul>
            </>
          ) : null}

          <div className="mt-8">
            <Button text="Log out" onClick={() => logout()} />
          </div>
        </Container>
      </Stack>
    </>
  );
}
