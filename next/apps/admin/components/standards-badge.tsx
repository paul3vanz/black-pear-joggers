export interface StandardsBadgeProps {
  standard: string;
}

export function StandardsBadge(props: StandardsBadgeProps) {
  let backgroundColourClass = '';

  switch (props.standard) {
    case 'Bronze':
      backgroundColourClass = 'bg-yellow-600';
      break;
    case 'Silver':
      backgroundColourClass = 'bg-gray-300';
      break;
    case 'Gold':
      backgroundColourClass = 'bg-yellow-400';
      break;
    case 'Platinum':
      backgroundColourClass = 'bg-gray-500';
      break;
  }

  return (
    <div className={'px-2 rounded py-1 text-white ' + backgroundColourClass}>
      {props.standard}
    </div>
  );
}
