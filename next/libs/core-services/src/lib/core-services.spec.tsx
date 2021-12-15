import { render } from '@testing-library/react';

import CoreServices from './core-services';

describe('CoreServices', () => {
  it('should render successfully', () => {
    const { baseElement } = render(<CoreServices />);
    expect(baseElement).toBeTruthy();
  });
});
