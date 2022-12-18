import { faUserCircle } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

interface UserIconProps {
  title?: string;
}

const UserIcon = (props: UserIconProps) => {
  return (
    <FontAwesomeIcon className="text-white" size="2x" icon={faUserCircle} />
  );
};

interface UserMenuProps {
  isAuthenticated: boolean;
  user: any;
  userProfile: any;
}

export const UserMenu = (props: UserMenuProps) => {
  const getUserDisplayName = (): string | undefined => {
    return props.userProfile
      ? `${props.userProfile.athlete.first_name} ${props.userProfile.athlete.last_name}`
      : props.user && props.user.name;
  };

  return props.isAuthenticated ? (
    <button
      onClick={() => {
        window.location.href = `${window.location.origin}/${
          props.userProfile ? 'profile' : 'register'
        }`;
      }}
    >
      {props.user?.picture ? (
        <img
          src={props.user.picture}
          alt={getUserDisplayName()}
          title={getUserDisplayName()}
          className="w-8 rounded-full"
        />
      ) : (
        <UserIcon />
      )}
    </button>
  ) : (
    <button
      onClick={() => {
        window.location.href = `${window.location.origin}/register`;
      }}
    >
      <UserIcon title="Log in" />
    </button>
  );
};
