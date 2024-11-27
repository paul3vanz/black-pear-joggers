export function buildAwardClaimBody(email: string, firstName: string, award: string, certificateId: string) {
    return {
        from: {
            name: 'Black Pear Joggers',
            email: 'webmaster@bpj.org.uk',
        },
        reply_to: {
            email: EMAIL_ADDRESS_AWARDS,
            name: AWARDS_COORDINATOR,
        },
        personalizations: [
            {
                to: [
                    {
                        email,
                    },
                ],
                dynamic_template_data: {
                    firstName,
                    award,
                    certificateId,
                },
            },
        ],
        template_id: "d-46f2fd008d2143cc92c4ee8a5e205c2c",
    };
}