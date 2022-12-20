import Link from 'next/link';
import { classNames } from '@black-pear-joggers/helpers';
import { Logo } from './components/logo';
import { MobileMenu } from './components/mobile-menu';
import { NavigationLinkItem, navigationLinks } from '../constants/navigation';
import { useAuth0 } from '@auth0/auth0-react';
import { useEffect, useRef, useState } from 'react';
import { UserMenu } from './components/user-menu';
import { useRouter } from 'next/router';
import { useUser } from '@black-pear-joggers/core-services';
import {
  NavigationLink,
  SubmenuNavigationLink,
} from './components/navigation-link';

const NavigationItem = (props: {
  item: NavigationLinkItem;
  active: boolean;
  onClick: (e: any) => void;
}) => {
  return (
    <li className="relative text-center lg:text-left" onClick={props.onClick}>
      <NavigationLink link={props.item.link} text={props.item.text} />

      {props.item.items && props.active && (
        <ul className="bg-gray-900 rounded-sm lg:absolute z-30 w-64 top-8 py-2">
          {props.item.items.map((item, index) => (
            <li key={index}>
              <SubmenuNavigationLink link={item.link} text={item.text} />
            </li>
          ))}
        </ul>
      )}
    </li>
  );
};

export const Header = () => {
  const { user, isAuthenticated } = useAuth0();
  const [menuOpen, setMenuOpen] = useState(false);
  const [active, setActive] = useState<number>();
  const { user: userProfile } = useUser(isAuthenticated);
  const menu = useRef<HTMLUListElement>(null);

  const handleClickOutside = (event: MouseEvent) => {
    if (menu.current && !menu.current.contains(event.target as Node)) {
      setActive(undefined);
      document.removeEventListener('mousedown', handleClickOutside);
    }
  };

  useEffect(() => {
    document.addEventListener('mousedown', handleClickOutside);

    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [handleClickOutside, active]);

  return (
    <nav className="bg-gray-900">
      <div className="container flex flex-col lg:flex-row justify-between items-center mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex justify-between w-full lg:w-auto">
          <Logo />

          <div className="lg:hidden flex items-center justify-self-start">
            <MobileMenu handleMenuClick={() => setMenuOpen(!menuOpen)} />
          </div>
        </div>

        <ul
          ref={menu}
          className={classNames(
            !menuOpen && 'hidden',
            'lg:flex flex-shrink flex-col lg:flex-row lg:ml-6 items-center mb-4 lg:mb-0'
          )}
        >
          {navigationLinks.map((item, index) => (
            <NavigationItem
              key={index}
              item={item}
              active={active === index}
              onClick={() => {
                setActive(index);
              }}
            ></NavigationItem>
          ))}

          <li className="flex lg:ml-4 justify-center mt-3 lg:mt-0">
            <UserMenu
              isAuthenticated={isAuthenticated}
              user={user}
              userProfile={userProfile}
            />
          </li>
        </ul>
      </div>
    </nav>
  );
};
