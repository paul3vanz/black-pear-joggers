/* eslint-disable @next/next/no-img-element */
import {
  Athlete,
  GenderFull,
  Performance,
} from '@black-pear-joggers/core-services';
import { shortUkDate } from '@black-pear-joggers/helpers';
import { Award } from 'apps/claim-award/types/award';

type Props = {
  athlete: Athlete;
  year: number;
  category: string;
  performances: Performance[];
  award: Award;
};

export function CertificatePreview(props: Props) {
  return (
    <div className="bg-white mb-8 w-auto p-4 relative">
      <img
        src={`https://bpj.org.uk/certificate/certificate-badge-${Award[
          props.award
        ].toLowerCase()}.png`}
        className="mb-4 w-20 right-4 absolute top-4"
        alt=""
      />

      <p className="uppercase font-semibold mb-0 text-xl">Club Standard</p>

      <p className="uppercase text-orange-400 font-extrabold text-3xl">
        Certificate
      </p>

      <p className="border-l-orange-400 pl-4 border-l-4 ml-4">
        This certificate is awarded to
        <br />
        <span className="text-orange-400 text-3xl font-['Pacifico']">
          {props.athlete.first_name} {props.athlete.last_name}
        </span>
        <br />
        For achieving the Black Pear Joggers{' '}
        <strong>{Award[props.award]}</strong> Standard in
        <br />
        the{' '}
        <strong>
          {GenderFull[props.athlete.gender]}{' '}
          {props.category.replace('SEN', 'Senior')}
        </strong>{' '}
        category for <strong>{props.year}</strong> with the following runs:
      </p>
      <table className="ml-8">
        <thead>
          <tr>
            <th className="text-orange-400 xs:hidden">Date</th>
            <th className="text-orange-400">Time</th>
            <th className="text-orange-400">Event</th>
            <th className="text-orange-400">Standard</th>
          </tr>
        </thead>

        <tbody>
          {props.performances
            .sort((a, b) =>
              Number(a.timeParsed) < Number(b.timeParsed) ? -1 : 1
            )
            .map((performance) => (
              <tr key={performance.id}>
                <td className="pr-4 xs:hidden">
                  {shortUkDate(performance.date)}
                </td>
                <td className="pr-4">
                  <strong>{performance.time}</strong>
                </td>
                <td className="pr-4">{performance.meetingName}</td>
                <td>{Award[performance.award]}</td>
              </tr>
            ))}
        </tbody>
      </table>
    </div>
  );
}
