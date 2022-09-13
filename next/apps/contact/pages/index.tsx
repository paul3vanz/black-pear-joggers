import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { GetStaticProps } from 'next';
import { Select, TextArea, TextInput } from '@black-pear-joggers/form-controls';
import { Stack } from '@black-pear-joggers/stack';
import { useState } from 'react';

export function ContactPage() {
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [isError, setIsError] = useState(false);

  function handleSubmit() {
    setIsLoading(true);
    setIsError(false);
    setIsSuccess(false);

    const myForm = document.getElementById('contact') as HTMLFormElement;
    fetch('https://contact.bpj.workers.dev/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: (document.getElementById('input-name') as HTMLInputElement).value,
        email: (document.getElementById('input-email') as HTMLInputElement)
          .value,
        reason: (document.getElementById('input-reason') as HTMLInputElement)
          .value,
        message: (
          document.getElementById('input-message') as HTMLTextAreaElement
        ).value,
      }),
    })
      .then((response) => response.json())
      .then((response) => {
        if (response.ok) {
          setIsSuccess(true);

          // Bodged until I hook up formik or similar
          (document.getElementById('input-name') as HTMLInputElement).value =
            '';
          (document.getElementById('input-email') as HTMLInputElement).value =
            '';
          (
            document.getElementById('input-message') as HTMLTextAreaElement
          ).value = '';
        } else {
          setIsError(true);
        }
      })
      .catch((error) => {
        setIsError(true);
      })
      .finally(() => setIsLoading(false));
  }

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
            <a href="https://bpj.org.uk/joining-the-club/">joining us</a>.
            Otherwise, you can get in touch with the right contact below.
          </p>
        </Container>
      </Stack>

      <Stack backgroundColour="dark">
        <Container>
          <form className="w-full max-w-lg" data-netlify="true" id="contact">
            {isSuccess ? (
              <p className="bg-green-300 px-6 py-4 text-black">
                Your message was sent successfully.
              </p>
            ) : null}
            {isError ? (
              <p className="bg-red-300 px-6 py-4 text-black">
                There was a problem sending your message. Please try again
                later.
              </p>
            ) : null}

            <input type="hidden" name="form-name" value="contact" />

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
                text={isLoading ? 'Sending...' : 'Send'}
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
