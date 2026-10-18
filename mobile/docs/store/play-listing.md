# Google Play store listing: BPJ

Text and assets for Play Console -> **Grow users -> Store presence -> Main store listing** (older Consoles: Store presence -> Main store listing). Everything here describes features that exist in the app today (checked against ROADMAP phases 1-6.5 and Phase 8, parkrun and race events). Do not add iOS wording until it ships (Phase 7c). If a release goes out before Phase 8 is deployed, delete the "PARKRUN AND RACES" section.

## Basics

| Field | Value |
|---|---|
| App name (max 30) | **BPJ** (3 characters). Alternative if you want search to find it: `BPJ - Black Pear Joggers` (24). |
| Subtitle options | The Play Store has no separate subtitle. The "short description" below does that job. (The iOS store will have a real one: "Club runs, groups and chat".) |
| Default language | English (United Kingdom) |
| App or game | App |
| Free or paid | **Free** (cannot be changed to paid later) |
| Application id | `uk.org.bpj.app` (cannot change after the first upload) |
| Category | **Sports** (alternatives: Health & Fitness; Sports fits a club app best) |
| Tags (pick up to 5 from Play's list) | Running; Sports; Social; Fitness; Community (use whatever the list offers; the list has no free text) |
| Website | https://bpj.org.uk |
| Email (public) | `webmaster@bpj.org.uk` |
| Target audience | **18 and over** only; not designed for children (the club has no members under 18). Set in Play Console -> App content -> Target audience and content: see [data-safety.md](data-safety.md) section 3. |
| Phone | leave blank (optional) |
| Privacy policy URL | https://bpj.org.uk/privacy-policy (must be live before you submit) |

## Short description (max 80 characters; pick one)

1. `Black Pear Joggers: club news, run times, pace groups and chat.` (63)
2. `Club runs, pace groups, reminders and chat for Black Pear Joggers members.` (74)
3. `Your Worcester running club: runs, pace groups, updates and group chat.` (71)

Recommended: option 2 (it says who it is for and what it does).

## Full description (max 4000 characters; the text below is about 2,400)

```
The members' app for Black Pear Joggers, the running club in Worcester.

See when and where we run, tell the leaders you are coming, join a pace group that suits you, and never miss club news again. Everything works with a poor signal too: the app keeps the latest runs, groups and updates on your phone.

Black Pear Joggers membership is needed to use the app. You sign in with Google, Facebook or your email address, then confirm you are a member with your membership (England Athletics) number and date of birth. Not a member yet? Find out how to join at bpj.org.uk.

CLUB UPDATES
- News from the committee in one place, with a push notification for the important things.
- Read past updates offline.
- An inbox keeps every notification, even if you missed the alert.

RUNS
- The weekly club runs by day, with the time, venue and a map link.
- Cancelled or changed runs are clearly marked, and you are told if a run you are going to changes.
- Sunday long runs show the route options for the day.

PACE GROUPS AND LEADERS
- See the groups on each run, with their pace, distance and leaders, shown in miles or kilometres, your choice.
- Tap "I'm coming", pick a group, and set your own pace for the run if it differs from usual.
- Leaders: offer to lead a group in a few taps, repeat last time's group, and step down if plans change.
- Committee: see which paces have a leader and where the gaps are.

REMINDERS
- A reminder for runs you usually go to, with "I'm coming" and "Not coming" buttons right in the notification.
- Choose which weekly runs remind you, and set a daily limit on notifications.
- Get told if a pace group needs a leader or a new group matches your pace.

GROUP CHAT
- A chat for each pace group on a run: "running 5 minutes late", "meet at the back car park".
- Messages are cached on your phone and sent when you are back online.
- Mute a chat any time. Chats close 12 hours after the run ends.

MEMBER PROFILES
- Add a photo and a short bio so people know who they are running with.
- Share your running goals with other members, or keep them private (the default).
- Tap a leader's or group member's name to see their profile.

PARKRUN AND RACES
- Going to a parkrun on Saturday? Pick which one, or add it, and see how many club members are heading to each.
- Every parkrun and race has its own chat, handy for sharing lifts and meeting up.
- Club races show up too, so you can say you are going.

YOUR PRIVACY
- Only members of the club can see what you add.
- No adverts, no tracking, no location.
- You can delete your account in the app (Profile -> About & privacy -> Delete my account).

Questions or feedback? Email webmaster@bpj.org.uk.
```

(Check the length after you edit: Play counts every character, including line breaks.)

## Release notes template ("What's new", max 500 characters per language)

```
Version 1.0.0
- First release for club members.
- Club updates and run reminders with push notifications.
- Run schedule, pace groups and leader sign-up.
- Group chat and member profile cards.
```

Template for later releases:

```
Version 1.x.y
- New: <one line>
- Improved: <one line>
- Fixed: <one line>
```

For Play closed testing, the same box is "Release notes" on the release page (use `<en-GB>` tags only if you add more languages).

## Assets checklist

| Asset | Spec | Source | Done |
|---|---|---|---|
| App icon | 512 x 512 px, PNG (32-bit), under 1 MB | `mobile/assets/icon/icon.png` is 1000 x 1000, so resize it to 512 x 512 (any image editor, or Squoosh). Keep the transparent or flat background as it is; do not add rounded corners or shadows, Play does that. | [ ] |
| Feature graphic | 1024 x 500 px, PNG or JPEG, no transparency | Make in Canva or Figma: club orange `#f89829` on black, logo, "Runs. Pace groups. Chat." Keep text away from edges. | [ ] |
| Phone screenshots | 2 to 8; PNG or JPEG; each side 320-3840 px; 16:9 to 9:16. Aim for 1080 x 2400. | Capture on a real phone or the emulator (Pixel 7, 1080 x 2400), light theme (and one dark if you like). | [ ] |
| 7-inch and 10-inch tablet screenshots | Optional. Skip for now (the app is phone-first). Play may later push for them for tablet reach. | | [ ] |
| Promo video | Optional | skip | [ ] |

### Phone screenshot shopping list (in this order, 6 to 8 shots)

Use a test account with a few believable runs and groups. No real members' faces or names: use test profiles or hide names. Turn on "demo mode" in the phone's developer settings for a clean status bar (full battery, 12:00, no notification icons).

1. **Updates**: the club updates list with a pinned or "important" post.
2. **Runs**: the week's runs by day, one cancelled banner, one "You're going".
3. **Run page**: the groups with pace, leaders (with photos) and counts.
4. **Pick your pace group** sheet after "I'm coming".
5. **Group chat**: a few messages, names and a "Leader" badge.
6. **Reminder notification** with the "I'm coming" / "Not coming" buttons (take it from the notification shade).
7. **Profile card** or another member's profile (photo, bio) and **Profile tab** with pace settings.
8. **Lead a run** (leader roster) or **Group coverage** (committee), if you want to show leader tools.

Add a short caption bar to each screenshot if you wish ("See who is leading", "Know your pace group"); do not add device frames that cover the app.

## Before you press publish

- [ ] Every claim in the description is in the app today (read it once against the release build).
- [ ] Contact email (`webmaster@bpj.org.uk`) and privacy policy URL are live, and the target audience is set to 18+ only.
- [ ] Screenshots show no real members' private details.
- [ ] Content rating, target audience, data safety, app access and account deletion are done: see [data-safety.md](data-safety.md).
