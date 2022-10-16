import React from 'react';

export const highlightIcon = () => (
  <span style={{ fontWeight: 'bold' }}>H</span>
);

export const highlightRender = (props) => (
  <span style={{ backgroundColor: 'yellow' }}>{props.children}</span>
);
