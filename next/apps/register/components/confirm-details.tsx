import { Athlete } from '@black-pear-joggers/core-services';
import { Button } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { formatGender } from '@black-pear-joggers/helpers';
import { Stack } from '@black-pear-joggers/stack';

export interface ConfirmDetailsProps {
  athlete: Athlete;
  isUpdating: boolean;
  onConfirmDetails: (athlete: Athlete) => void;
}

export function ConfirmDetails(props: ConfirmDetailsProps) {
  return (
    <Stack backgroundColour="bright">
      <Container>
        <h2>Check your details</h2>

        <p>We think we found you! Please check the details below.</p>

        <ul className="mb-6 text-xl">
          <li>
            Name:{' '}
            <strong>
              {props.athlete.first_name} {props.athlete.last_name}
            </strong>
          </li>
          <li>
            Gender: <strong>{formatGender(props.athlete.gender)}</strong>
          </li>
          <li>
            Age category:<strong> {props.athlete.category}</strong>
          </li>
        </ul>

        <Button
          text={props.isUpdating ? 'Please wait...' : 'Confirm'}
          onClick={() => props.onConfirmDetails(props.athlete)}
        />
      </Container>
    </Stack>
  );
}
