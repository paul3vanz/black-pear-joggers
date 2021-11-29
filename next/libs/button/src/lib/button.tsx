import styled from 'styled-components';
import styledMap from 'styled-map';

interface Props {
  link?: string;
  text: string;
  colour?: string;
  backgroundColour?: string;
  fullWidth?: boolean;
  size?: string;
  onClick?: (e: React.MouseEvent) => void;
  as?: React.ElementType;
}

const styles = {
  colour: styledMap('colour', {
    light: '#fff',
    default: '#232323',
  }),
  activeColour: styledMap('colour', {
    light: '#232323',
    default: '#fff',
  }),
  backgroundColour: styledMap('colour', {
    light: '#232323',
    default: 'transparent',
  }),
  padding: styledMap('size', {
    sm: '0.25rem 0.5rem',
    default: '0.5rem 1rem',
  }),
  fontSize: styledMap('size', {
    sm: '1.125rem',
    default: '1.25rem',
  }),
};

const StyledButton = styled.a<Props>`
  font-weight: bold;
  cursor: pointer;
  display: inline-block;
  transition: all 0.3s ease;
  border: 2px solid ${styles.colour};
  border-radius: 3px;
  color: ${styles.colour};
  padding: ${styles.padding};
  font-size: ${styles.fontSize};
  background-color: ${styles.backgroundColour};
  width: ${(props) => (props.fullWidth ? '100%' : 'auto')};
  &:hover,
  &:focus {
    background-color: ${styles.colour};
    color: ${styles.activeColour};
  }
`;

export const Button = (props: Props) => (
  <StyledButton {...props} href={props.link}>
    {props.text}
  </StyledButton>
);

export const ButtonLightText = styled(Button).attrs((props: Props) => ({
  colour: 'light',
}))``;

export const ButtonLightTextDarkBackground = styled(Button).attrs(
  (props: Props) => ({
    backgroundColour: 'dark',
    colour: 'light',
  })
)``;
