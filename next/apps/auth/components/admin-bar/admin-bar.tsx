import { useAuth0 } from '@auth0/auth0-react';
import { Container } from '@black-pear-joggers/container';

import Link from 'next/link';

interface MenuItemProps {
  link: string;
  title: string;
}

function MenuItem(props: MenuItemProps) {
  return (
    <li className="mr-4">
      <Link href={props.link}>
        <a>{props.title}</a>
      </Link>
    </li>
  );
}

function Menu() {
  return (
    <ul className="flex flex-col md:flex-row justify-around">
      <MenuItem link="/athletes" title="Athletes" />

      <MenuItem link="/club-standards" title="Club standards" />

      <MenuItem link="/magic-mile" title="Magic mile" />

      <MenuItem link="/clubs/1606/members" title="Members" />

      <MenuItem link="/clubs" title="Clubs" />

      <MenuItem link="/tools" title="Tools" />
    </ul>
  );
}

export default function AdminBar() {
  const { user, logout, isAuthenticated } = useAuth0();

  return isAuthenticated ? (
    <div className="py-4 bg-gray-200">
      <Container>
        <div className="flex justify-between">
          <nav>
            <Menu />
          </nav>

          <div>
            <a
              href="#"
              onClick={() => logout({ returnTo: window.location.origin })}
            >
              {user && user.name}
            </a>
          </div>
        </div>
      </Container>
    </div>
  ) : (
    <></>
  );
}
