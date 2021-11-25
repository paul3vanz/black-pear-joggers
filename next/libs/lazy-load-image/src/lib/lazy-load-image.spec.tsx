import { render } from '@testing-library/react';

import LazyLoadImage from './lazy-load-image';

describe('LazyLoadImage', () => {
  it('should render successfully', () => {
    const { baseElement } = render(<LazyLoadImage />);
    expect(baseElement).toBeTruthy();
  });
});
