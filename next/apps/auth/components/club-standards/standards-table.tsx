import { Standard } from '../../services/award-claims.interface';

export function StandardsTable(props: {
  gender: string;
  category: string;
  standards: Standard[];
  standardClaimed: string;
}) {
  const filteredStandards = props.standards
    ? getStandardsByEvent(
        props.standards.filter((standard) => {
          return (
            standard.gender === props.gender &&
            standard.category === props.category
          );
        })
      )
    : null;

  return filteredStandards ? (
    <table className="w-full">
      <thead>
        <tr>
          <th></th>

          {['Bronze', 'Silver', 'Gold', 'Platinum'].map((standard) => (
            <th
              key={standard}
              className={
                'p-2 border ' +
                (standard === props.standardClaimed ? 'bg-gray-200' : '')
              }
            >
              {standard}
            </th>
          ))}
        </tr>
      </thead>
      <tbody>
        {filteredStandards.map((event, i) => (
          <tr key={i}>
            <th className="p-2 border">{event.name}</th>

            {event.standards.map((standard, i) => (
              <td
                className={
                  'p-2 border ' +
                  (props.standardClaimed === standard.name ? 'bg-gray-200' : '')
                }
                key={i}
              >
                {standard.time}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  ) : null;
}

export function getStandardsByEvent(standards: Standard[]) {
  const output: Array<Record<string, any>> = [{ events: [] }];
  let currentEvent: string = null;
  let currentAward: string = null;
  let currentEventIndex = -1;
  let currentAwardIndex = -1;

  standards.forEach((s) => {
    if (currentEvent !== s.event) {
      ++currentEventIndex;
      currentEvent = s.event;
      output[currentEventIndex] = { name: currentEvent, standards: [] };
      currentAwardIndex = -1;
    }
    if (currentAward !== s.name) {
      ++currentAwardIndex;
      currentAward = s.name;
      output[currentEventIndex].standards[currentAwardIndex] = {
        name: s.name,
        time: s.time,
        timeParsed: s.time_parsed,
        event: s.event,
      };
    }
  });

  return output;
}
