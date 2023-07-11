import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { useCountdown } from '../core/hooks/countdown';

export function CountdownTimer() {
  const [days, hours, minutes, seconds] = useCountdown('2023-07-16 09:30:00');

  return days + hours + minutes + seconds > 0 ? (
    <Stack backgroundColour={BackgroundColour.Bright}>
      <Container>
        <ul className="flex text-center justify-center">
          <CountdownElement value={days} label="Days" />
          <CountdownElement value={hours} label="Hours" />
          <CountdownElement value={minutes} label="Minutes" />
          <CountdownElement value={seconds} label="Seconds" />
        </ul>
      </Container>
    </Stack>
  ) : null;
}

function CountdownElement(props: { value: number; label: string }) {
  return (
    <li className="border border-orange-500 flex flex-col content-center px-2 sm:px-10 py-4 mr-4">
      <strong className="text-3xl sm:text-4xl">{props.value}</strong>
      <span className="">{props.label}</span>
    </li>
  );
}
