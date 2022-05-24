import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { GetStaticProps } from 'next';
import { Select, TextArea, TextInput } from '@black-pear-joggers/form-controls';
import { Stack } from '@black-pear-joggers/stack';

type ContactPageProps = {
  isLoading: boolean;
  categories: {
    title: string;
    description: string;
    slug: {
      current: string;
    };
    imageUrl: string;
  }[];
};

function handleSubmit() {
  let myForm = document.getElementById('contact') as HTMLFormElement;
  let formData = new FormData(myForm);
  fetch('/', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams(formData).toString(),
  })
    .then(() => console.log('Form successfully submitted'))
    .catch((error) => alert(error));
}

export function ContactPage(props: ContactPageProps) {
  return (
    <>
      <Stack>
        <Container>
          <h1>Contact the club</h1>

          <p>
            If you&apos;re interested in joining, find out more about{' '}
            <a href="https://bpj.org.uk/joining-the-club/">joining us</a>.
            Otherwise, you can get in touch with the right contact below.
          </p>
        </Container>
      </Stack>

      <Stack backgroundColour="dark">
        <Container>
          <form className="w-full max-w-lg" data-netlify="true" id="contact">
            <div className="flex flex-wrap -mx-3 mb-6">
              <div className="w-full md:w-2/3 px-3 mb-6 md:mb-0">
                <TextInput
                  id="name"
                  label="Name"
                  // error={errors.urn && 'Please enter a valid number'}
                  required={true}
                />
              </div>
            </div>

            <div className="flex flex-wrap -mx-3 mb-6">
              <div className="w-full md:w-2/3 px-3 mb-6 md:mb-0">
                <TextInput
                  id="email"
                  label="Email address"
                  // error={errors.urn && 'Please enter a valid number'}
                  required={true}
                />
              </div>
            </div>

            <div className="flex flex-wrap -mx-3 mb-6">
              <div className="w-full md:w-2/3 px-3 mb-6 md:mb-0">
                <Select
                  id="reason"
                  label="Reason for contacting"
                  options={[
                    'Joining / Membership enquiry',
                    'Send news / race report',
                    'Problem with the website',
                    'Social event enquiry',
                    'Race: Croome Capability Canter',
                    'Race: The Wild One',
                    'Race: Worcester Festival Run',
                    'Kit enquiry',
                    'Welfare',
                    'Mental Health',
                    'Club Standards Awards',
                    'Cross Country',
                    'Other',
                  ]}
                />
              </div>
            </div>

            <div className="flex flex-wrap -mx-3 mb-6">
              <div className="w-full md:w-2/3 px-3 mb-6 md:mb-0">
                <TextArea
                  id="message"
                  label="Message"
                  // error={errors.urn && 'Please enter a valid number'}
                  required={true}
                />
              </div>
            </div>

            <div className="mb-6">
              <ButtonLightTextDarkBackground
                text={props.isLoading ? 'Sending...' : 'Send'}
                onClick={handleSubmit}
              />
            </div>
          </form>
        </Container>
      </Stack>

      <Stack backgroundColour="bright">
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
