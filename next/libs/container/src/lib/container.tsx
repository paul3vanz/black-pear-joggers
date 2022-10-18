import styled from 'styled-components';
import { classNames } from '@black-pear-joggers/helpers';
import { PropsWithChildren } from 'react';

const Wrapper = styled.div`
  & > *:last-child {
    margin-bottom: 0;
  }
`;

interface Props {
  wide?: boolean;
}

export const Container = (props: PropsWithChildren<Props>) => (
  <div className={classNames('container mx-auto', !props.wide && 'max-w-4xl')}>
    <div className="px-4">
      <Wrapper>{props.children}</Wrapper>
    </div>
  </div>
);
