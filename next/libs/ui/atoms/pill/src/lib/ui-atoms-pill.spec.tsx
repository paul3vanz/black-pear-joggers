import { render } from '@testing-library/react';

import UiAtomsPill from './ui-atoms-pill';

describe('UiAtomsPill', () => {
  it('should render successfully', () => {
    const { baseElement } = render(<UiAtomsPill />);
    expect(baseElement).toBeTruthy();
  });
});
