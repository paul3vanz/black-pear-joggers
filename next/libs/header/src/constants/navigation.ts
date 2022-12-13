export interface NavigationLinkItem {
    link: string;
    text: string;
    items?: NavigationLinkItem[];
}

export const navigationLinks: NavigationLinkItem[] = [
    { link: 'https://bpj.org.uk/membership', text: 'Membership' },
    {
        link: '#',
        text: 'Club info',
        items: [
            { link: 'https://bpj.org.uk/the-history-of-black-pear-joggers', text: 'Our history' },
            { link: 'https://bpj.org.uk/meet-the-joggers', text: 'Meet the joggers' },
            { link: 'https://bpj.org.uk/kit', text: 'Kit' },
            { link: 'https://bpj.org.uk/charity', text: 'Charity' },
            { link: 'https://bpj.org.uk/mental-health-and-wellbeing', text: 'Mental health and wellbeing' },
            { link: 'https://bpj.org.uk/london-marathon-club-ballot', text: 'London ballot places' },
            { link: 'https://bpj.org.uk/leading-a-group', text: 'Leading a group' },
            { link: 'https://bpj.org.uk/social-events', text: 'Social events' },
        ],
    },
    {
        link: '#',
        text: 'Racing/leagues',
        items: [
            { link: 'https://bpj.org.uk/leagues/champions-league', text: 'Champions league' },
            { link: 'https://apps.bpj.org.uk/club-standards', text: 'Club standards awards' },
            { link: 'https://bpj.org.uk/leagues/cross-country', text: 'Cross country' },
            { link: 'https://apps.bpj.org.uk/magic-mile', text: 'Magic mile' },
            { link: 'https://bpj.org.uk/leagues/parkrun-tours', text: 'parkrun tours' },
            { link: 'https://apps.bpj.org.uk/club-records', text: 'Club records' },
            { link: 'https://apps.bpj.org.uk/race-results', text: 'Race results' },
        ],
    },
    {
        link: '#',
        text: 'Our races',
        items: [
            { link: 'https://bpj.org.uk/our-races/croome-capability-canter', text: 'Croome Capability Canter' },
            { link: 'https://bpj.org.uk/our-races/the-wild-one', text: 'The Wild One' },
            { link: 'https://www.entrycentral.com/worcesterfestivalrun', text: 'Worcester Festival Run' },
        ],
    },

    { link: 'https://bpj.org.uk/news', text: 'News' },
    {
        link: '#',
        text: 'Contact',
        items: [
            { link: 'https://bpj.org.uk/contact', text: 'Contact the club' },
            { link: 'https://www.facebook.com/groups/blackpearjoggers/', text: 'Facebook community' },
            { link: 'https://bpj.typeform.com/to/pIodcN', text: 'Incident report form' },
        ],
    },
];