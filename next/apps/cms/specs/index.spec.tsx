import Index from '../pages/home';
import React from 'react';
import { render } from '@testing-library/react';


describe('Index', () => {
  it('should render successfully', () => {
    const { baseElement } = render(<Index />);
    expect(baseElement).toBeTruthy();
  });
});
