/* eslint-disable @next/next/no-img-element */
import {
  Athlete,
  GenderFull,
  Performance,
} from '@black-pear-joggers/core-services';
import { shortUkDate } from '@black-pear-joggers/helpers';
import { Award } from 'apps/claim-award/src/types/award';
import { useRef } from 'react';

type Props = {
  athlete: Athlete;
  year: number;
  category: string;
  performances: Performance[];
  award: Award;
};

export function CertificatePreview(props: Props) {
  const certificateRef = useRef<HTMLDivElement>(null);
  const certificatePrintContainer = document.getElementById(
    'certificate-print-container'
  );

  function onPrintClick() {
    if (certificatePrintContainer && certificateRef.current) {
      certificatePrintContainer.innerHTML = certificateRef.current.innerHTML;
      setTimeout(() => window.print(), 500);
    }
  }

  return (
    <>
      <div
        ref={certificateRef}
        className="certificate bg-white mb-4 w-auto p-4 relative bg-[url('https://bpj.org.uk/certificate/certificate.png')] bg-[length:1px_1px] bg-no-repeat"
      >
        <img
          src={`https://bpj.org.uk/certificate/certificate-badge-${Award[
            props.award
          ].toLowerCase()}.png`}
          className="badge mb-4 w-20 right-4 absolute top-4 print:top-auto print:bottom-4 print:right-12"
          alt=""
        />

        <svg
          className="h-12 mb-4"
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 400 113.74"
        >
          <path
            d="M84.36.1c-.17.06-.49.23-.7.38-.4.26-.77.59-3.76 3.37-2.8 2.6-2.79 2.6-5.15 1.93a38.25 38.25 0 0 0-8.24-1.61c-.94-.08-6.99-.11-8.1-.05a42.6 42.6 0 0 0-6.34.88c-.26.05-.64.07-1.34.07-1.32 0-1.54-.05-3.8-.83C35.16.17 25.33 1.9 17.2 9.48 9.7 16.47 5.14 27.85 3.06 44.75c-.32 2.6-.58 3.57-1.46 5.4C-.08 53.66-.3 54.47.37 55.08c.38.36.72.46 1.92.56.45.04.92.1 1.04.12 2.04.38 6.48-.05 9.65-.95 6.16-1.74 11.86-5.41 17.16-11.06l1.84-1.94a47.2 47.2 0 0 0 5.45-6.8c1.7-2.57 2.5-4.13 5.6-10.75 3.6-7.67 5.77-11.27 7.63-12.6.7-.5 3.82-1.78 6.41-2.62 3.73-1.2 9.22-2 11.95-1.74 2.56.25 4.78.69 5.27 1.05.75.53.34 1.91-1.32 4.4-1.78 2.68-2.45 3.13-4.38 2.93-5.57-.57-10.2 1.1-14.65 5.3-2.75 2.6-3.97 4.24-4.6 6.22a43 43 0 0 1-.84 2.49c-1.9 5.04-5.36 10.43-12.35 19.2-6.61 8.32-8.92 11.58-10.97 15.47-3.63 6.93-4.74 12.67-3.93 20.41.73 6.92 4.98 14.46 11.23 19.95 2.68 2.34 7.48 5.44 9.97 6.42 6.67 2.65 16.46 3.36 23.4 1.7 9.6-2.3 18.08-9.16 21.84-17.69a27.05 27.05 0 0 0 2.14-13.46c-.5-4.17-1.03-6.78-3.27-16.15-1.94-8.12-2.45-10.4-2.78-12.54a161.1 161.1 0 0 1-.76-5.7 86.52 86.52 0 0 1-.22-6.3c.06-.81.54-4.98.7-6.06.38-2.6.35-3.6-.19-5.76a19.42 19.42 0 0 0-6.86-10.8 17.6 17.6 0 0 1-1.13-.98c-.67-.81-.48-1.6.69-2.96 2.31-2.7 4.4-4.07 10.89-7.18 2.78-1.34 3.2-1.68 3.2-2.6 0-1.08-1.35-2.64-3.39-3.92C85.5 0 85.04-.13 84.36.1M37.22 5.07c2.5.31 4.4.8 7.77 2 2.86 1.02 3.05 1.4 2.23 4.59a8.7 8.7 0 0 1-1.45 3.38 63.82 63.82 0 0 0-5.52 10.51c-2.2 5.1-5.02 9.9-7.44 12.65a170.31 170.31 0 0 1-4.68 5.14c-3.76 3.79-8.61 6.93-13.07 8.47-3.55 1.22-9.86 1.6-10.9.67-.78-.7-.71-2.87.15-4.88.57-1.32.76-2.15 1.09-4.68.06-.5.22-1.56.35-2.36l.39-2.6c1.06-7.43 3.99-15.97 7.05-20.6 3.54-5.36 6.78-8.3 11.63-10.51 2.8-1.28 4.5-1.72 7.3-1.86.96-.05 4.5 0 5.1.08m81.57 29.23v16.64l9.59-.01 9.58-.02 1.25-.15c3.67-.44 4.86-.72 6-1.4a9.1 9.1 0 0 0 4.36-8.92c-.37-3.77-2.44-6.01-6.6-7.17l-.22-.07.34-.13c3.23-1.24 4.96-3.72 4.97-7.11 0-4.35-2.83-7.39-7.6-8.17l-.65-.1-10.5-.02-10.52-.01V34.3m35.88 0v16.64h9.27V17.66h-9.27V34.3m76.38 0v16.64h9.46V44.7l1.73-1.67c1.34-1.31 1.73-1.67 1.77-1.62l2.43 4.8 2.39 4.73h5.23c4.23 0 5.23-.01 5.2-.06 0-.03-2.04-3.53-4.52-7.78a617.9 617.9 0 0 1-4.52-7.79c0-.05 7.2-7.13 8.55-8.4.06-.06-.78-.07-5.68-.07h-5.74l-3.41 3.96-3.4 3.96-.02-8.55-.01-8.55h-9.46V34.3m47.1 0v16.64h10.38V38.57l3.83-.02c4.16-.02 4.29-.03 5.76-.31 5.43-1.06 8.27-4.63 8.27-10.38 0-5.6-2.58-8.94-7.66-9.92-1.4-.27-.72-.25-11.07-.27l-9.51-.01V34.3M66.9 20.42c4.3.21 6.6 1.15 9.2 3.77a17.57 17.57 0 0 1 4.98 10.04c.15.89.14 1.84-.02 2.9a88.3 88.3 0 0 0-.84 7.22c0 .59.2 3.5.33 4.99.25 2.8.94 7.03 1.87 11.56.19.9.5 2.15 1 3.97.53 1.96.93 3.72 2.22 9.73 1.02 4.74 1.1 5.48 1.06 9.05-.04 3-.25 4.35-1.07 6.8a27.38 27.38 0 0 1-9.24 13.13c-3.73 3-6.94 4.43-12.67 5.62-3.16.66-3.04.64-6 .66-2.72.01-2.63.02-4.8-.4-.57-.12-1.78-.34-2.69-.5-2.4-.4-3.48-.66-4.92-1.2-9.72-3.55-18.2-13.62-19.74-23.4-.15-.95-.17-8.58-.03-9.53.43-2.8 1.77-6.7 3.4-9.82 1.88-3.64 3.61-6.14 9.4-13.59 7.58-9.73 9.76-13.31 12.14-19.95.94-2.6 1.4-3.32 3.67-5.59 1.81-1.82 2.9-2.7 4.43-3.58A15.61 15.61 0 0 1 66 20.38l.9.04m68.21 4.07c1.99.33 2.8 1.2 2.8 3.02 0 1.83-.84 2.75-2.8 3.06-.4.06-.99.08-3.19.1l-2.7.03v-6.33l2.73.02c2.15.02 2.81.04 3.16.1m156.82-.02c2.06.1 3.06.5 3.78 1.55 1.23 1.74.66 4.27-1.16 5.16-1.02.5-2.19.66-4.97.66h-1.05v-7.41h1.29c.7 0 1.66.02 2.12.04m-111.99 1.84l-.78.07c-5.33.43-8.15 2.2-9.36 5.85-.17.52-.43 1.5-.4 1.53.03.02 8.62.91 8.76.91.1 0 .13-.05.28-.4.69-1.73 1.78-2.35 4.25-2.41 2.57-.07 3.53.66 3.53 2.7v.29l-.76.28c-1.98.73-3.38 1.08-8.46 2.11-3.67.75-5.32 1.41-6.56 2.64-2.04 2.03-2.38 5.79-.74 8.25 1.53 2.3 3.98 3.36 7.79 3.36 3.9 0 6.38-.85 8.85-3.05l.42-.37.12.65c.14.7.3 1.14.63 1.78l.22.41 4.37.02h4.37l-.26-.6c-.9-2-.86-1.6-.9-9.7-.03-6.44-.04-6.65-.13-7.1-1-4.84-3.3-6.62-9.23-7.14-.8-.07-5.47-.13-6-.08m31.7.02c-4.73.4-7.96 2.16-10.12 5.49-2.3 3.54-2.5 9.97-.42 13.6 2.2 3.82 5.6 5.68 11.1 6.03 5.84.38 9.7-.73 12.46-3.58a12.35 12.35 0 0 0 2.92-5.29l.03-.15-4.32-.47c-5.13-.57-4.49-.55-4.63-.16-.8 2.26-2.36 3.36-4.73 3.36-3.43 0-5.32-2.63-4.96-6.92.3-3.66 2.05-5.54 5.15-5.54 2.25 0 3.66.94 4.2 2.78.09.32-.51.36 4.52-.31l4.3-.57-.02-.12a13.1 13.1 0 0 0-1.92-3.8c-1.84-2.47-4.4-3.77-8.4-4.27-.85-.1-4.27-.16-5.16-.08m108.9 0c-7.36.69-11.75 5.4-11.75 12.63 0 3.4.84 5.94 2.74 8.3 2.42 3 5.35 4.15 10.7 4.22 6.23.08 9.49-1.05 12.23-4.25.63-.73 1.82-2.46 1.74-2.52l-4.56-.43-4.55-.4-.64.64A4.3 4.3 0 0 1 322.9 46c-2.61 0-4.32-1.65-4.64-4.5l-.03-.3h18.5V40.2c0-8.45-3.68-12.9-11.4-13.8-.73-.08-4.07-.13-4.77-.06m30.52-.02l-.79.07c-5.32.43-8.15 2.2-9.36 5.85-.17.52-.42 1.5-.4 1.53.03.02 8.62.91 8.76.91.1 0 .14-.05.28-.4.7-1.73 1.79-2.35 4.25-2.41 2.57-.07 3.54.66 3.54 2.7v.29l-.77.28c-1.98.73-3.38 1.08-8.46 2.11-3.67.75-5.32 1.41-6.56 2.64-2.04 2.03-2.38 5.79-.74 8.25 1.53 2.3 3.99 3.36 7.8 3.36 3.9 0 6.37-.85 8.84-3.05l.42-.37.13.65c.14.7.3 1.14.63 1.78l.21.41 4.37.02h4.37l-.26-.6c-.9-2-.86-1.6-.9-9.7-.03-6.44-.03-6.65-.12-7.1-1-4.84-3.3-6.62-9.24-7.14-.8-.07-5.46-.13-6-.08m34.3.04c-1.88.35-3.05 1.35-4.33 3.71l-.33.6v-3.82h-8.67v24.1h9.31l.02-5.13c.02-5.37.03-5.7.25-7.18.64-4.49 2.55-5.96 6.04-4.65.28.1.52.18.53.17.03-.03 2.85-6.55 2.85-6.59A11.8 11.8 0 0 0 388 26.4c-.5-.1-2.1-.13-2.61-.04M324 31.91c1.9.52 2.97 2.01 3.25 4.56l.03.29h-4.53c-2.49 0-4.52-.02-4.52-.04 0-.16.2-1.23.3-1.56.51-1.77 1.67-2.93 3.3-3.29.43-.1 1.77-.07 2.17.04m-189.04 5.17c1.81.08 2.77.4 3.47 1.14 1.37 1.44.97 4.04-.77 4.95-1.04.54-1.86.63-5.98.63h-2.47v-6.77h2.45c1.34 0 2.83.02 3.3.05m51.26 3.53c0 1.5-.1 2.16-.47 2.95-1.3 2.83-6.24 3.8-7.48 1.46-.68-1.26-.14-2.66 1.28-3.34.86-.42 1.17-.52 4.04-1.31a38.22 38.22 0 0 0 2.6-.83c.02 0 .03.48.03 1.07m171.13 0c0 1.5-.1 2.16-.47 2.95-1.3 2.83-6.25 3.8-7.5 1.46-.66-1.26-.13-2.66 1.3-3.34.85-.42 1.16-.52 4.04-1.31a38.22 38.22 0 0 0 2.6-.83c.01 0 .03.48.03 1.07M132.64 72.06c-.01 10.1-.02 10.93-.1 11.5-.34 2.6-1.29 3.67-3.24 3.67-2.14 0-3.23-1.66-3.23-4.92 0-.44 0-.46-.1-.46-.14 0-9.74 1.3-9.77 1.33-.17.15.4 3.14.82 4.4 1.6 4.67 5.01 6.98 10.92 7.4 5.2.36 8.86-.69 11.6-3.3 1.97-1.89 2.8-3.86 3.22-7.6.2-1.83.2-1.75.22-12.5l.01-10.4h-10.33l-.02 10.88m26.43-2.23l-.62.07c-7.65.8-12.43 6.79-11.5 14.38.66 5.26 4.48 9.29 9.87 10.39 2.36.48 5.4.48 7.77 0 6.47-1.3 10.45-6.61 9.97-13.3-.46-6.42-4.6-10.6-11.36-11.45-.55-.08-3.69-.14-4.13-.09m27.49 0l-.53.07c-4.09.51-7.09 3.6-7.9 8.15-1.43 7.94 2.23 14.62 8.43 15.39 3 .37 5.8-.56 7.87-2.63l.66-.66-.02 2.44c-.01 2.3-.02 2.48-.11 2.9-.48 2.1-1.5 2.88-3.79 2.88-2.02 0-3.11-.67-3.55-2.17l-.05-.19-4.41-.5-4.5-.5c-.2 0-.19 1.9.02 2.93a6.96 6.96 0 0 0 4.06 5.04c3.55 1.56 11.38 1.73 15.48.34a9.27 9.27 0 0 0 6.16-7.68c.1-.7.1.03.08-13.64l-.01-11.64h-8.67v1.72l-.02 1.71-.38-.48a8.36 8.36 0 0 0-5.5-3.38c-.5-.08-2.96-.16-3.32-.1m31.47 0l-.53.07c-4.09.51-7.09 3.6-7.9 8.15-1.43 7.94 2.23 14.62 8.43 15.39 3.01.37 5.8-.56 7.87-2.63l.66-.66-.01 2.44c-.02 2.3-.03 2.48-.12 2.9-.47 2.1-1.5 2.88-3.79 2.88-2.02 0-3.11-.67-3.54-2.17l-.06-.19-4.4-.5-4.52-.5c-.2 0-.18 1.9.03 2.93a6.96 6.96 0 0 0 4.07 5.04c3.55 1.56 11.38 1.73 15.47.34a9.27 9.27 0 0 0 6.16-7.68c.1-.7.1.03.08-13.64V70.36h-8.68v1.72l-.02 1.71-.38-.48a8.36 8.36 0 0 0-5.5-3.38c-.5-.08-2.96-.16-3.32-.1m34.07.02c-7.36.69-11.75 5.41-11.75 12.63 0 3.4.84 5.94 2.74 8.3 2.42 3 5.35 4.15 10.71 4.22 6.22.09 9.48-1.05 12.22-4.25.63-.73 1.82-2.45 1.74-2.52-.01 0-2.06-.2-4.56-.42l-4.54-.42-.65.65a4.3 4.3 0 0 1-3.57 1.48c-2.61.01-4.32-1.65-4.64-4.5l-.03-.3h18.5v-1c0-8.46-3.68-12.91-11.4-13.8-.73-.09-4.07-.13-4.77-.07m33.81.03c-1.88.35-3.04 1.34-4.33 3.7l-.33.6v-3.82h-8.67v24.1h9.31l.02-5.13c.02-5.37.03-5.69.25-7.17.64-4.5 2.55-5.97 6.04-4.66l.53.18c.03-.04 2.86-6.56 2.86-6.6a11.53 11.53 0 0 0-3.06-1.17c-.5-.1-2.11-.13-2.62-.03m17.13-.03c-3.24.26-5.37.98-7.03 2.37a6.7 6.7 0 0 0 1.44 11.14c1.2.6 3.17 1.1 6.8 1.76 4.29.77 4.97 1.02 5.4 1.97.7 1.5-.94 2.81-3.5 2.8-2.25 0-3.45-.76-4.16-2.64l-.13-.34h-.2l-4.61.43-4.43.42.1.42c.74 2.85 2.74 5 5.52 5.93 3.67 1.23 10.6 1.24 14.14.02 4.8-1.65 7.17-6.27 5.3-10.33-1.38-2.97-4.07-4.24-10.75-5.07-3.97-.5-4.96-.93-4.96-2.17 0-1.17 1.04-1.82 2.92-1.82 2.01 0 3.28.75 3.71 2.19.05.16.08.2.18.2.13 0 8.68-.85 8.7-.86.02-.01-.05-.2-.14-.42-1.41-3.4-3.63-5.2-7.12-5.76a45.46 45.46 0 0 0-7.18-.24m-47.49 5.58c1.9.52 2.97 2.01 3.25 4.56l.03.29h-4.52c-2.5 0-4.53-.02-4.53-.04 0-.16.2-1.23.3-1.56.51-1.77 1.68-2.93 3.3-3.29.43-.1 1.77-.07 2.17.04m-93.51.95c1.53.5 2.61 1.85 3.01 3.77.31 1.5.24 3.88-.17 5.27a4.28 4.28 0 0 1-8.28.18 11.2 11.2 0 0 1 .1-6.56 4.34 4.34 0 0 1 5.34-2.66m30.06.28c1.88.6 2.95 2.3 3.06 4.9.16 3.5-1.48 5.66-4.22 5.57-2.7-.1-4.1-2.34-3.78-6.08.2-2.38.95-3.71 2.41-4.3.66-.26 1.86-.3 2.53-.09m31.47 0c1.88.6 2.95 2.3 3.06 4.9.16 3.5-1.48 5.66-4.21 5.57-2.7-.1-4.1-2.34-3.8-6.08.2-2.38.96-3.71 2.42-4.3.66-.26 1.87-.3 2.53-.09"
            fill-rule="evenodd"
            fill="#000"
          />
        </svg>

        <p className="uppercase font-semibold mb-0 text-xl">Club Standard</p>

        <p className="uppercase text-orange-400 font-extrabold text-3xl">
          Certificate
        </p>

        <p className="summary border-l-orange-400 pl-4 border-l-4 sm:ml-4 print:ml-6">
          This certificate is awarded to
          <br />
          <span className="text-orange-400 text-3xl font-['Pacifico']">
            {props.athlete.first_name} {props.athlete.last_name}
          </span>
          <br />
          For achieving the Black Pear Joggers{' '}
          <strong>{Award[props.award]}</strong> Standard in{' '}
          <br className="hidden sm:inline print:inline" />
          the{' '}
          <strong>
            {GenderFull[props.athlete.gender as keyof typeof GenderFull]}{' '}
            {props.category.replace('SEN', 'Senior')}
          </strong>{' '}
          category for <strong>{props.year}</strong> with the following runs:
        </p>

        <div className="overflow-auto print:overflow-visible">
          <table className="events sm:ml-8 print:ml-12 print:text-xs">
            <thead>
              <tr>
                <th className="text-orange-400 hidden sm:table-cell print:table-cell">
                  Date
                </th>
                <th className="text-orange-400">Time</th>
                <th className="text-orange-400">Event</th>
                <th className="text-orange-400 hidden xs:table-cell print:table-cell">
                  Standard
                </th>
              </tr>
            </thead>

            <tbody>
              {props.performances
                .sort((a, b) =>
                  Number(a.timeParsed) < Number(b.timeParsed) ? -1 : 1
                )
                .map((performance) => (
                  <tr key={performance.id}>
                    <td className="pr-4 hidden sm:table-cell print:table-cell">
                      {shortUkDate(performance.date)}
                    </td>
                    <td className="pr-4">
                      <strong>{performance.time}</strong>
                    </td>
                    <td className="pr-4">
                      <span className="overflow-hidden text-ellipsis whitespace-nowrap max">
                        {performance.meetingName}
                      </span>
                    </td>
                    <td className="hidden xs:table-cell print:table-cell">
                      {Award[performance.award!]}
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>
        </div>
      </div>

      <p className="mb-8">
        <button className="underline font-bold" onClick={() => onPrintClick()}>
          Print certificate
        </button>
      </p>
    </>
  );
}
