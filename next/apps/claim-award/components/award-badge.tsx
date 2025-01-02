import { classNames } from '@black-pear-joggers/helpers';

type Props = {
  award: Award;
};

export enum Award {
  Bronze = 1,
  Silver = 2,
  Gold = 3,
  Platinum = 4,
}

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
    <div className={classNames('rounded-md text-white px-2', classes)}>
      {Award[props.award]}
    </div>
  );
}
