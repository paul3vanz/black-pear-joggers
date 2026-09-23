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
      { link: '/club-runs', text: 'Club runs' },
      { link: '/the-history-of-black-pear-joggers', text: 'Our history' },
      { link: '/meet-the-joggers', text: 'Meet the joggers' },
      { link: '/kit', text: 'Kit' },
      { link: '/charity', text: 'Charity' },
      {
        link: '/mental-health-and-wellbeing',
        text: 'Mental health and wellbeing',
      },
      { link: '/london-marathon-club-ballot', text: 'London ballot places' },
      { link: '/leading-a-group', text: 'Leading a group' },
      { link: '/social-events', text: 'Social events' },
    ],
  },
  {
    link: '#',
    text: 'Racing/leagues',
    items: [
      {
        link: '/leagues/champions-league',
        text: 'Champions league',
      },
      {
        link: 'https://apps.bpj.org.uk/club-standards',
        text: 'Club standards awards',
      },
      {
        link: '/leagues/cross-country',
        text: 'Cross country',
      },
      { link: 'https://apps.bpj.org.uk/magic-mile', text: 'Magic mile' },
      {
        link: '/leagues/parkrun-tours',
        text: 'parkrun tours',
      },
      { link: 'https://apps.bpj.org.uk/club-records', text: 'Club records' },
      { link: 'https://apps.bpj.org.uk/race-results', text: 'Race results' },
    ],
  },
  {
    link: '#',
    text: 'Our races',
    items: [
      {
        link: '/our-races/the-wild-one',
        text: 'The Wild One',
      },
      {
        link: 'https://www.entrycentral.com/worcesterfestivalrun',
        text: 'Worcester Festival Run',
      },
      {
        link: '/our-races/croome-capability-canter',
        text: 'Croome Capability Canter',
      },
      {
        link: '/our-races/croome-by-night',
        text: 'Croome by Night',
      },
    ],
  },

  { link: '/news', text: 'News' },
  {
    link: '#',
    text: 'Contact',
    items: [
      { link: '/contact', text: 'Contact the club' },
      {
        link: 'https://www.facebook.com/groups/blackpearjoggers/',
        text: 'Facebook community',
      },
      {
        link: 'https://bpj.typeform.com/to/pIodcN',
        text: 'Incident report form',
      },
    ],
  },
];
