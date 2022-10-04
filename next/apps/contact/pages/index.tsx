import { ButtonLightTextDarkBackground } from '@black-pear-joggers/button';
import { Container } from '@black-pear-joggers/container';
import { GetStaticProps } from 'next';
import { Select, TextArea, TextInput } from '@black-pear-joggers/form-controls';
import { Stack } from '@black-pear-joggers/stack';
import { useForm } from 'react-hook-form';
import { useState } from 'react';

interface FormData {
  name: string;
  email: string;
  reason: string;
  message: string;
}

export function ContactPage() {
  const [isLoading, setIsLoading] = useState(false);
  const [isSuccess, setIsSuccess] = useState(false);
  const [isError, setIsError] = useState(false);

  const {
    getValues,
    formState: { errors },
    setValue,
    register,
    handleSubmit,
  } = useForm<FormData>();

  function submitEnquiry(formData: FormData) {
    setIsLoading(true);
    setIsError(false);
    setIsSuccess(false);

    fetch('https://contact.bpj.workers.dev/', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(formData),
    })
      .then((response) => response.json())
      .then((response) => {
        if (response.send.ok) {
          setIsSuccess(true);
          setValue('name', '');
          setValue('email', '');
          setValue('message', '');
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
                  placeholder="Name"
                  labelHidden={true}
                  required={true}
                  error={errors.name && 'Please enter your name'}
                  registerField={register('name', {
                    required: true,
                  })}
                />
              </div>
            </div>

            <div className="flex flex-wrap -mx-3 mb-6">
              <div className="w-full md:w-2/3 px-3 mb-6 md:mb-0">
                <TextInput
                  id="email"
                  label="Email address"
                  placeholder="Email address"
                  labelHidden={true}
                  required={true}
                  error={errors.email && 'Please enter a valid email address'}
                  registerField={register('email', {
                    required: true,
                    pattern:
                      /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/,
                  })}
                />
              </div>
            </div>

            <div className="flex flex-wrap -mx-3 mb-6">
              <div className="w-full md:w-2/3 px-3 mb-6 md:mb-0">
                <Select
                  id="reason"
                  label="Reason for contacting"
                  labelHidden={true}
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
                  registerField={register('reason', {
                    required: true,
                  })}
                />
              </div>
            </div>

            <div className="flex flex-wrap -mx-3 mb-6">
              <div className="w-full md:w-2/3 px-3 mb-6 md:mb-0">
                <TextArea
                  id="message"
                  label="Message"
                  labelHidden={true}
                  placeholder="Message"
                  required={true}
                  error={errors.message && 'Please enter your message'}
                  registerField={register('message', {
                    required: true,
                  })}
                />
              </div>
            </div>

            <div className="mb-6">
              <ButtonLightTextDarkBackground
                text={isLoading ? 'Sending...' : 'Send'}
                onClick={handleSubmit(submitEnquiry)}
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
