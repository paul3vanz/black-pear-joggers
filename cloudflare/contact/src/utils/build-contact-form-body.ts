import { mapSubjectToRecipient } from "./map-subject-to-recipient";

export function buildContactFormBody(name: string, email: string, reason: string, message: string) {
    return {
        personalizations: [
            {
                to: [
                    {
                        name: 'Black Pear Joggers',
                        email: mapSubjectToRecipient(reason),
                    },
                ],
                bcc: [
                    {
                        name: 'Black Pear Joggers',
                        email: EMAIL_ADDRESS_DEBUG,
                    },
                ],
            },
        ],
        from: {
            name: name,
            email: 'webmaster@bpj.org.uk',
        },
        reply_to: {
            email: email,
            name: name,
        },
        subject: reason + ' (Black Pear Joggers Website Enquiry)',
        content: [
            {
                type: 'text/plain',
                value: `${message}

  Sent by: ${name} (${email})`,
            },
        ],
    };
}