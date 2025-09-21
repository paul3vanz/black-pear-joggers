import { BackgroundColour, Stack } from '@black-pear-joggers/stack';
import { Container } from '@black-pear-joggers/container';
import { GetStaticProps } from 'next';
import { Select } from '@black-pear-joggers/form-controls';
import { Button } from '@black-pear-joggers/button';
import { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/router';

export function ContactPage() {
  const [selectedReason, setSelectedReason] = useState('');
  const router = useRouter();
  const { reason } = router.query;
  const sendMessageStack = useRef(null);

  const contactReasons = {
    membership: 'Joining / Membership enquiry',
    news: 'Send news / race report',
    website: 'Problem with the website',
    social: 'Social event enquiry',
    croome: 'Race: Croome Capability Canter',
    wildone: 'Race: The Wild One',
    festivalrun: 'Race: Worcester Festival Run',
    kit: 'Kit enquiry',
    welfare: 'Welfare',
    mentalhealth: 'Mental Health',
    championsleague: 'Champions League',
    clubstandards: 'Club Standards Awards',
    crosscountry: 'Cross Country',
    other: 'Other',
  };

  const contactInfo = {
    'Joining / Membership enquiry': {
      description: (
        <>
          Interested in joining Black Pear Joggers? Please first read our{' '}
          <a href="https://bpj.org.uk/membership" className="underline">
            membership information
          </a>{' '}
          to learn about training sessions, club events, and what we offer. If
          you still have questions after reading this, our membership team is
          here to help.
        </>
      ),
      email: 'membership@bpj.org.uk',
    },
    'Send news / race report': {
      description: (
        <>
          Have exciting running news or a race report to share? Send us your
          stories and photos to share with the club and local running community.
        </>
      ),
      email: 'webmaster@bpj.org.uk',
    },
    'Problem with the website': {
      description: (
        <>
          Experiencing technical issues with our website? If you want to report
          a problem or have suggestions for improvements, we value your
          feedback.
        </>
      ),
      email: 'webmaster@bpj.org.uk',
    },
    'Social event enquiry': {
      description: (
        <>
          Want to know about our social events? Browse our{' '}
          <a
            href="https://www.facebook.com/groups/blackpearjoggers/events"
            className="underline"
          >
            events calendar
          </a>{' '}
          first to see upcoming social gatherings and celebrations. If you have
          ideas for new activities or need more information, get in touch below.
        </>
      ),
      email: 'eventsbpj@gmail.com',
    },
    'Race: Croome Capability Canter': {
      description: (
        <>
          Questions about our Croome Capability Canter race? Please visit the{' '}
          <a
            href="https://bpj.org.uk/our-races/croome-capability-canter"
            className="underline"
          >
            race information page
          </a>{' '}
          first for entry details, course information, and event schedule. For
          additional questions about entering or volunteering, contact our race
          team.
        </>
      ),
      email: 'eventsbpj@gmail.com',
    },
    'Race: The Wild One': {
      description: (
        <>
          Interested in The Wild One trail race? Check the{' '}
          <a
            href="https://bpj.org.uk/our-races/the-wild-one"
            className="underline"
          >
            race details page
          </a>{' '}
          first for course information, entry requirements, and race day
          details. For further questions about this challenging trail race or
          volunteering opportunities, contact us below.
        </>
      ),
      email: 'eventsbpj@gmail.com',
    },
    'Race: Worcester Festival Run': {
      description: (
        <>
          Want to know about the Worcester Festival Run? Please read the{' '}
          <a
            href="https://www.entrycentral.com/worcesterfestivalrun"
            className="underline"
          >
            race information
          </a>{' '}
          first for entry details, course map, and event information. If you
          need additional help or want to volunteer, our race team is here to
          assist.
        </>
      ),
      email: 'webmaster@bpj.org.uk',
    },
    'Kit enquiry': {
      description: (
        <>
          Looking for official Black Pear Joggers kit? Browse our{' '}
          <a href="https://bpj.org.uk/kit" className="underline">
            kit shop
          </a>{' '}
          first to see available items, sizes, and prices. If you need help with
          sizing, custom orders, or have questions not covered on the kit page,
          contact our kit coordinator.
        </>
      ),
      email: 'secretarybpj+kit@gmail.com',
    },
    Welfare: {
      description: (
        <>
          For confidential guidance or to discuss personal matters related to
          the club, our welfare officers are here to help.
        </>
      ),
      email: 'welfare@bpj.org.uk',
    },
    'Mental Health': {
      description: (
        <>
          Looking for mental health support? Start by reading our{' '}
          <a
            href="https://bpj.org.uk/mental-health-and-wellbeing/"
            className="underline"
          >
            wellbeing resources
          </a>{' '}
          For additional support or to discuss our wellbeing initiatives,
          contact our team below.
        </>
      ),
      email: 'welfarebpj@gmail.com',
    },
    'Champions League': {
      description: (
        <>
          Questions about our Champions League? Check the{' '}
          <a
            href="https://bpj.org.uk/leagues/champions-league"
            className="underline"
          >
            league information
          </a>{' '}
          first for fixtures, results, and rules. If you have specific
          questions, get in touch below.
        </>
      ),
      email: 'bpjleague@gmail.com',
    },
    'Club Standards Awards': {
      description: (
        <>
          Want to know about Club Standards Awards? Please review the{' '}
          <a
            href="https://apps.bpj.org.uk/club-standards/"
            className="underline"
          >
            awards criteria and times
          </a>{' '}
          first to see qualifying standards for different age categories and
          distances. If you have questions, get in touch.
        </>
      ),
      email: 'webmaster@bpj.org.uk',
    },
    'Cross Country': {
      description: (
        <>
          Interested in cross country running? Start by reading our{' '}
          <a
            href="https://bpj.org.uk/leagues/cross-country"
            className="underline"
          >
            cross country information
          </a>{' '}
          to learn about training sessions, fixtures, and what to expect. For
          questions or getting started with cross country, contact us below.
        </>
      ),
      email: 'secretarybpj+xc@gmail.com',
    },
    Other: {
      description: (
        <>
          Have a question that doesn't fit other categories? Please check our{' '}
          <a href="https://bpj.org.uk/site-map" className="underline">
            site map
          </a>{' '}
          first to see if there's a page that can help. If you can't find what
          you're looking for there, get in touch below.
        </>
      ),
      email: 'webmaster@bpj.org.uk',
    },
  };

  useEffect(() => {
    if (reason && contactReasons[reason.toString()]) {
      setSelectedReason(contactReasons[reason.toString()]);
      setTimeout(
        () =>
          sendMessageStack.current.scrollIntoView({
            behavior: 'smooth',
          }),
        1000
      );
    }
  }, [reason]);

  const handleReasonChange = (event) => {
    setSelectedReason(event.target.value);
  };

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

      <Stack>
        <Container>
          <h1>Contact the club</h1>

          <p>
            If you&apos;re interested in joining, find out more about{' '}
            <a href="https://bpj.org.uk/membership">joining us</a>. Otherwise,
            you can get in touch with the right contact below.
          </p>
        </Container>
      </Stack>

      <Stack backgroundColour={BackgroundColour.Dark}>
        <Container>
          <h2 ref={sendMessageStack}>Get in touch</h2>

          <div className="w-full max-w-xl">
            <div className="flex flex-wrap -mx-3 mb-6">
              <div className="w-full md:w-2/3 px-3 mb-6 md:mb-0">
                <Select
                  id="reason"
                  label="Reason for contacting"
                  labelHidden={true}
                  options={['Select a reason...', ...Object.keys(contactInfo)]}
                  onChange={handleReasonChange}
                />
              </div>
            </div>

            {selectedReason &&
              selectedReason !== 'Select a reason...' &&
              contactInfo[selectedReason] && (
                <div className="mt-6">
                  <p className="mb-4">
                    {contactInfo[selectedReason].description}
                  </p>
                  <div>
                    <Button
                      link={`mailto:${contactInfo[selectedReason].email}`}
                      text={contactInfo[selectedReason].email}
                      colour="light"
                    />
                  </div>
                </div>
              )}
          </div>
        </Container>
      </Stack>

      <Stack backgroundColour={BackgroundColour.Bright}>
        <Container>
          <h2>Our Facebook community</h2>

          <p>
            We also have a very active{' '}
            <a href="https://www.facebook.com/groups/blackpearjoggers/">
              Facebook group
            </a>{' '}
            page where you can chat to other club members.
          </p>
        </Container>
      </Stack>
    </>
  );
}

export const getStaticProps: GetStaticProps = async () => {
  return {
    props: {},
  };
};

export default ContactPage;
