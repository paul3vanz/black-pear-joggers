import Link from 'next/link';

interface FooterLinkProps {
  link: string;
  text: string;
}

function FooterLink({ link, text }: FooterLinkProps) {
  return (
    <li>
      <Link href={link}>
        <a className="md:mx-3 no-underline hover:underline">{text}</a>
      </Link>
    </li>
  );
}

export function Footer() {
  return (
    <>
      <div>
        <img
          src="https://bpj.org.uk/wp-content/uploads/2022/09/club-photo.jpg"
          alt=""
          className="w-full object-cover h-64 sm:h-auto"
          width="1080"
          height="212"
        />
      </div>

      <footer className="text-center bg-gray-900 text-white py-8">
        <img
          src="https://bpj.org.uk/wp-content/themes/BPJ/england-athletics-logo.svg"
          alt="England Athletics"
          width="200"
          height="68"
          className="mb-8 mx-auto"
        />

        <ul className="flex flex-col space-y-4 md:space-y-0 md:flex-row justify-center">
          <FooterLink link="/club-constitution" text="Club constitution" />

          <FooterLink
            link="/health-and-safety-policy-and-risk-assessment"
            text="Health and safety policy"
          />

          <FooterLink link="/privacy-policy" text="Privacy policy" />

          <FooterLink link="/terms-of-use" text="Terms of use" />

          <FooterLink link="/site-map" text="Site map" />
        </ul>
      </footer>
    </>
  );
}
