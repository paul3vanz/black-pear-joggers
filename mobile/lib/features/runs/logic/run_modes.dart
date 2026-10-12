/// Helpers for a run's `groupMode` (a plain string from the server).
///
/// Modes: `paced`, `single`, `open`, `routes` (Phases 1-5) and `events`,
/// `race` (Phase 8, D76). Keeping the checks here means a screen asks a
/// question ("does this run use pace groups?") instead of comparing strings,
/// a bit like a small `selectors.ts` module in a React app.
library;

/// A day on which people go to different events (e.g. a Saturday parkrun
/// series). Its groups are the individual events.
bool isEventsMode(String mode) => mode == 'events';

/// A one-off race: exactly one event, created with the run.
bool isRaceMode(String mode) => mode == 'race';

/// Either of the two event modes: no pace, leaders or coverage (D79).
bool isEventLikeMode(String mode) => isEventsMode(mode) || isRaceMode(mode);

/// Whether the run is organised into pace groups with leaders: `paced`,
/// `single` and `open`. False for `routes` (the coordinator sets routes) and
/// for `events`/`race`, so pace notes, the pick-a-group prompt, coverage and
/// the leader roster all stay off for them.
bool usesPaceGroups(String mode) => mode != 'routes' && !isEventLikeMode(mode);

/// The modes a weekly series can have. Races are one-off, so the server
/// rejects a `race` series.
const seriesGroupModes = ['paced', 'single', 'open', 'routes', 'events'];

/// The modes an ad-hoc run can have.
const adHocGroupModes = ['paced', 'single', 'open', 'routes', 'events', 'race'];
