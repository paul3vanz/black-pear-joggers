import styled from 'styled-components';
import { classNames } from '@black-pear-joggers/helpers';

export interface PillProps {
  active?: boolean;
  onClick: () => void;
  text: string;
}

export function Pill(props: PillProps) {
  return (
    <button
      onClick={props.onClick}
      className={classNames(
        props.active && 'font-bold bg-green-600 text-white',
        !props.active && 'bg-gray-200 text-black',
        'inline-block px-2 py-1 ml-2 rounded-md'
      )}
    >
      {props.text}
    </button>
  );
}
