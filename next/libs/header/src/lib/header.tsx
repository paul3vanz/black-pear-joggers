import Link from 'next/link';
import { faUserCircle } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { NavigationLinkItem, navigationLinks } from '../constants/navigation';
import { useAuth0 } from '@auth0/auth0-react';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import { useUser } from '@black-pear-joggers/core-services';

const NavigationLink = (props: { link: string; text: string }) => (
  <a
    className="text-gray-100 transition-all hover:bg-gray-700 hover:text-white px-3 py-1 inline-block rounded-sm font-bold no-underline text-center leading-tight"
    href={props.link}
  >
    {props.text}
  </a>
);

const SubmenuNavigationLink = (props: { link: string; text: string }) => (
  <a
    className="text-gray-100 transition-all hover:text-white py-1 px-3 block font-bold no-underline hover:bg-gray-700"
    href={props.link}
  >
    {props.text}
  </a>
);

const NavigationItem = (props: { item: NavigationLinkItem }) => {
  const [active, setActive] = useState(false);

  const handleClick = (e: MouseEvent) => {
    setActive(false);
  };

  useEffect(() => {
    if (!active) {
      return;
    }

    document.addEventListener('click', handleClick);

    return () => {
      document.removeEventListener('click', handleClick);
    };
  }, [handleClick, active]);

  return (
    <li
      className="relative text-center lg:text-left"
      onClick={() => setActive(!active)}
    >
      <NavigationLink link={props.item.link} text={props.item.text} />

      {props.item.items && active && (
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

interface MobileMenuProps {
  handleMenuClick: () => void;
}

const MobileMenu = (props: MobileMenuProps) => (
  <button
    onClick={props.handleMenuClick}
    type="button"
    className="inline-flex items-center justify-center p-2 rounded-sm text-gray-400 hover:text-white transition-all hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-white"
    aria-controls="mobile-menu"
    aria-expanded="false"
  >
    <span className="sr-only">Open main menu</span>

    <svg
      className="block h-6 w-6"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      aria-hidden="true"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2"
        d="M4 6h16M4 12h16M4 18h16"
      />
    </svg>

    <svg
      className="hidden h-6 w-6"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      aria-hidden="true"
    >
      <path
        strokeLinecap="round"
        strokeLinejoin="round"
        strokeWidth="2"
        d="M6 18L18 6M6 6l12 12"
      />
    </svg>
  </button>
);

const Logo = () => (
  <Link href="https://bpj.org.uk">
    <a>
      <img
        className="h-8 sm:h-12 w-auto my-4"
        src="https://bpj.org.uk/download-logo/bpj-logo-alt.svg"
        alt="Black Pear Joggers Logo"
        width="190"
        height="54"
      />
    </a>
  </Link>
);

function UserIcon(props: { title?: string }) {
  return (
    <FontAwesomeIcon className="text-white" size="2x" icon={faUserCircle} />
  );
}

export const Header = () => {
  const { user, loginWithRedirect, logout, isAuthenticated } = useAuth0();
  const [menuOpen, setMenuOpen] = useState(false);
  const router = useRouter();
  const { user: userProfile } = useUser(isAuthenticated);

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
          className={[
            !menuOpen && 'hidden',
            'lg:flex flex-shrink flex-col lg:flex-row lg:ml-6 items-center mb-4 lg:mb-0',
          ].join(' ')}
        >
          {navigationLinks.map((item, index) => (
            <NavigationItem key={index} item={item}></NavigationItem>
          ))}

          <li className="flex lg:ml-4 justify-center mt-3 lg:mt-0">
            {isAuthenticated ? (
              <button
                onClick={() => {
                  window.location.href = `${window.location.origin}/${
                    userProfile ? 'profile' : 'register'
                  }`;
                }}
              >
                {user?.picture ? (
                  <>
                    <img
                      src={user?.picture}
                      alt={
                        userProfile
                          ? `${userProfile.athlete.first_name} ${userProfile.athlete.last_name}`
                          : user && user.name
                      }
                      title={
                        userProfile
                          ? `${userProfile.athlete.first_name} ${userProfile.athlete.last_name}`
                          : user && user.name
                      }
                      className="w-8 rounded-full"
                    />
                  </>
                ) : (
                  <UserIcon />
                )}
              </button>
            ) : (
              <button onClick={() => router.push('/register')}>
                <UserIcon title="Log in" />
              </button>
            )}
          </li>
        </ul>
      </div>
    </nav>
  );
};
