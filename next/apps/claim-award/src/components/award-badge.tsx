import { Award } from '@black-pear-joggers/core-services';
import { classNames } from '@black-pear-joggers/helpers';

type Props = {
  award: Award;
};

export function AwardBadge({ award }: Props) {
  if (award === Award.None) {
    return null;
  }

  let classes;

  switch (award) {
    case Award.Bronze:
      classes = 'bg-yellow-700';
      break;
    case Award.Silver:
      classes = 'bg-gray-300';
      break;
    case Award.Gold:
      classes = 'bg-yellow-400';
      break;
    case Award.Platinum:
      classes = 'bg-gray-600';
      break;
  }

  return (
    <div className={classNames('rounded-md text-white px-2', classes)}>
      {Award[award]}
    </div>
  );
}
