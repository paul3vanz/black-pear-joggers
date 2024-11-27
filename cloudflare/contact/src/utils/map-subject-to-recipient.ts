export function mapSubjectToRecipient(subject) {
    const mappings = [
        { subject: 'Joining / Membership enquiry', recipient: EMAIL_ADDRESS_SECRETARY },
        { subject: 'Send news / race report', recipient: EMAIL_ADDRESS_SECRETARY },
        { subject: 'Problem with the website', recipient: EMAIL_ADDRESS_WEBMASTER },
        { subject: 'Social event enquiry', recipient: EMAIL_ADDRESS_EVENTS },
        { subject: 'Race: Croome Capability Canter', recipient: EMAIL_ADDRESS_EVENTS },
        { subject: 'Race: The Wild One', recipient: EMAIL_ADDRESS_EVENTS },
        { subject: 'Race: Worcester Festival Run', recipient: EMAIL_ADDRESS_WEBMASTER },
        { subject: 'Kit enquiry', recipient: EMAIL_ADDRESS_KIT },
        { subject: 'Welfare', recipient: EMAIL_ADDRESS_WELFARE },
        { subject: 'Mental Health', recipient: EMAIL_ADDRESS_WELFARE },
        { subject: 'Champions League', recipient: EMAIL_ADDRESS_LEAGUE },
        { subject: 'Club Standards Awards', recipient: EMAIL_ADDRESS_AWARDS },
        { subject: 'Cross Country', recipient: EMAIL_ADDRESS_CROSS_COUNTRY },
        { subject: 'Other', recipient: EMAIL_ADDRESS_SECRETARY },
    ];
    return mappings.find((mapping) => mapping.subject === subject).recipient;
}