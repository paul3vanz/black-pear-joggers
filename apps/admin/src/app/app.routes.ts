export const routes = [
  {
    path: '',
    redirectTo: 'athletes',
    pathMatch: 'full'
  },
  {
    path: 'athletes',
    loadChildren: () =>
      import('./athletes/athletes.module').then(m => m.AthletesModule)
  },
  {
    path: 'club-standards',
    loadChildren: () =>
      import('./club-standards/club-standards.module').then(
        m => m.ClubStandardsModule
      )
  },
  {
    path: 'magic-mile',
    loadChildren: () =>
      import('./magic-mile/magic-mile.module').then(m => m.MagicMileModule)
  },
  {
    path: 'auth',
    loadChildren: () =>
      import('libs/authentication/src/lib/auth/auth.module').then(
        m => m.AuthModule
      )
  }
];
