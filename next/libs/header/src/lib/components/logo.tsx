import Link from 'next/link';

export const Logo = () => (
  <Link href="https://bpj.org.uk">
    <img
      className="h-8 sm:h-12 w-auto my-4"
      src="https://bpj.org.uk/download-logo/bpj-logo-alt.svg"
      alt="Black Pear Joggers Logo"
      width="190"
      height="54"
    />
  </Link>
);
