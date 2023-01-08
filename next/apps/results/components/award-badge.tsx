import { Award } from './awards.type';
import { classNames } from '@black-pear-joggers/helpers';

type Props = {
  award: Award;
};

export function AwardBadge(props: Props) {
  let classes;

  switch (props.award) {
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
    <span className={classNames('rounded-md text-white px-2', classes)}>
      {Award[props.award]}
    </span>
  );
}
