export interface NavigationLinkItem {
    link: string;
    text: string;
    items?: NavigationLinkItem[];
}

export const navigationLinks: NavigationLinkItem[] = [
    { link: '/membership', text: 'Membership' },
    {
        link: '#',
        text: 'Club info',
        items: [
            { link: 'https://bpj.org.uk/when-we-run/', text: 'When We Run' },
            { link: 'https://bpj.org.uk/the-history-of-black-pear-joggers/', text: 'Our History' },
            { link: 'https://bpj.org.uk/meet-the-joggers/', text: 'Meet the Joggers' },
            { link: 'https://bpj.org.uk/kit/', text: 'Kit' },
            { link: 'https://bpj.org.uk/charity/', text: 'Charity' },
            { link: 'https://bpj.org.uk/mental-health-and-wellbeing/', text: 'Mental Health and Wellbeing' },
            { link: 'https://bpj.org.uk/london-marathon-club-ballot/', text: 'London Ballot Places' },
            { link: 'https://bpj.org.uk/leading-a-group/', text: 'Leading a Group' },
            { link: 'https://bpj.org.uk/social-events/', text: 'Social Events' },
        ],
    },
    {
        link: '#',
        text: 'Racing/leagues',
        items: [
            { link: 'https://black-pear-joggers.netlify.com/apps/club-standards/', text: 'Club Standards Awards' },
            { link: 'https://bpj.org.uk/leagues/cross-country/', text: 'Cross Country' },
            { link: 'https://black-pear-joggers.netlify.com/apps/magic-mile/', text: 'Magic Mile' },
            { link: 'https://bpj.org.uk/leagues/parkrun-tours/', text: 'parkrun tours' },
            { link: 'https://black-pear-joggers.netlify.com/apps/club-records/', text: 'Club Records' },
            { link: 'https://black-pear-joggers.netlify.com/apps/race-results/', text: 'Race Results' },
        ],
    },
    {
        link: '#',
        text: 'Our races',
        items: [
            { link: 'https://bpj.org.uk/our-races/croome-race/', text: 'Croome Capability Canter' },
            { link: 'https://bpj.org.uk/our-races/wild-race/', text: 'The Wild One' },
            { link: 'https://bpj.org.uk/the-virtual-wild-one/', text: 'The Virtual One' },
        ],
    },

    { link: '/news', text: 'News' },
    {
        link: '#',
        text: 'Contact',
        items: [
            { link: 'https://bpj.org.uk/contact-the-club/', text: 'Contact the Club' },
            { link: 'https://www.facebook.com/groups/blackpearjoggers/', text: 'Facebook Community' },
            { link: 'https://bpj.typeform.com/to/pIodcN', text: 'Incident Report Form' },
        ],
    },
];