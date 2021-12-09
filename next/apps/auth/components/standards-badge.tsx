export interface StandardsBadgeProps {
  standard: string;
}

export function StandardsBadge(props: StandardsBadgeProps) {
  let backgroundColourClass: string;

  switch (props.standard) {
    case 'Bronze':
      backgroundColourClass = 'bg-yellow-700';
      break;
    case 'Silver':
      backgroundColourClass = 'bg-gray-300';
      break;
    case 'Gold':
      backgroundColourClass = 'bg-yellow-400';
      break;
    case 'Platinum':
      backgroundColourClass = 'bg-gray-600';
      break;
  }

  return (
    <div className={'px-2 rounded py-1 text-white ' + backgroundColourClass}>
      {props.standard}
    </div>
  );
}
