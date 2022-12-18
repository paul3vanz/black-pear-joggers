interface NavigationLinkProps {
  link: string;
  text: string;
}

export const NavigationLink = (props: NavigationLinkProps) => (
  <a
    className="text-gray-100 transition-all hover:bg-gray-700 hover:text-white px-3 py-1 inline-block rounded-sm font-bold no-underline text-center leading-tight"
    href={props.link}
  >
    {props.text}
  </a>
);

export const SubmenuNavigationLink = (props: NavigationLinkProps) => (
  <a
    className="text-gray-100 transition-all hover:text-white py-1 px-3 block font-bold no-underline hover:bg-gray-700"
    href={props.link}
  >
    {props.text}
  </a>
);
