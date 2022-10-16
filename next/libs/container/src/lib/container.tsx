import styled from 'styled-components';
import { PropsWithChildren } from 'react';

const Wrapper = styled.div`
  & > *:last-child {
    margin-bottom: 0;
  }
`;

interface Props {}

export const Container = ({ children }: PropsWithChildren<Props>) => (
  <div className="container mx-auto max-w-4xl">
    <div className="px-4">
      <Wrapper>{children}</Wrapper>
    </div>
  </div>
);
