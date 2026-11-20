# Apple review round 1: Guideline 2.1 "Information Needed" (2026-11-20)

Apple wants six things in the **App Review Information -> Notes** box, then a resubmit. No code change is required by this message alone, but see "Before you resubmit" first: the reviewer will test user-generated content, and the app has no Report or Block yet (D44, app-store-listing.md section 9). Submitting without them risks a second rejection under Guideline 1.2.

## Before you resubmit

1. **Report + Block: built 2026-11-20 (D138), not yet run on a device or against production.** Apply `api/database/manual/2026_11_reports_blocks.sql`, deploy the API, bump the build number, upload a new build, and film it. (Original reasoning:) Apple's item 1 says to show "content reporting and blocking mechanisms" if the app has user-generated content. It does: group/event chat, update comments, profile photo, bio, goals. Minimum that satisfies 1.2:
   - Report a message or a profile card -> the committee is told (email or inbox row) and sees it.
   - Block a member -> their messages and profile card are hidden from you.
   - Published contact: `webmaster@bpj.org.uk` (About screen already has a contact link).
   - Replace the `[REPORT/BLOCK]` line in the notes below once it exists, and film it.
2. **Demo account must work on production**: email + password login from [data-safety.md](data-safety.md) section 4.2, linked test URN/DOB, and the test athlete row must survive the nightly sync. Check on the exact build you submit.
3. **Sign in with Apple** must be live in Auth0 (ROADMAP 7c). Guideline 4.8, and the notes mention it.
4. **Test the build on a real iPhone** (TestFlight), including push and account deletion against production.
5. Fill the `[...]` placeholders below.

## Screen recording (item 1)

Physical iPhone, latest iOS, QuickTime (Mac, USB cable, File -> New Movie Recording -> choose the iPhone) or iOS Screen Recording. One continuous take, about 3 minutes, upload it somewhere Apple can open without signing in (unlisted link) and paste the URL in the notes, or attach it if App Store Connect offers the field.

Order:
1. Home screen -> tap the BPJ icon (launch).
2. Sign-in screen -> Universal Login -> Continue with Apple (show the button), then sign in with the demo email account.
3. Link your membership: URN + DOB -> "Find me" -> "That's me".
4. Allow notifications prompt.
5. Updates tab: open an update, open Comments.
6. Runs tab: open a run, "I'm coming", pick a pace group, open the group chat, send a message.
7. **Report** that message, **Block** a member, show the blocked member's content disappearing.
8. Profile: profile card (photo, bio, goals, share setting).
9. Profile -> About & privacy -> Delete my account: show the screen, type DELETE, confirm, app returns to sign-in. Do this last, with a throwaway account (not the reviewer's login), or stop at the confirm screen with the reviewer account.
10. There are no paid features: say so on camera or in a caption.

## Notes to paste (under 4000 characters)

```
BPJ is the free members' app of Black Pear Joggers, a running club in Worcester, UK (https://bpj.org.uk). No in-app purchases, ads, subscriptions, tracking or paid content.

1. SCREEN RECORDING (physical iPhone, latest iOS): [URL]. It starts at launch and shows sign-in, linking membership, updates, runs and pace groups, group chat, reporting and blocking, profile card and account deletion.

2. PURPOSE AND AUDIENCE
For adult members (18+) of the club. Club news used to get lost in email and social media, and run leaders had no easy way to know who is coming and at what pace. The app gives members: club updates with push notifications, the weekly run schedule, "I'm coming" and pace-group sign-up, group chat for each run (e.g. "running 5 minutes late"), reminders, and an optional member profile card. Leaders see who is coming and cover pace groups; the committee posts updates. Membership itself is arranged on the club website, not in the app.

3. HOW TO ACCESS THE MAIN FEATURES
Demo account (member): [email] / [password]
a) Tap "Sign in". On the login page enter the demo email and password.
b) "Link your membership": URN [test URN], date of birth [test DOB], tap "Find me", then "That's me". (A demo membership record is used; no real member is involved.)
c) Tabs: Updates, Runs, Inbox, Profile. Open a run -> "I'm coming" -> choose a pace group -> open the group's chat.
d) Report / Block: press and hold another member's chat message (or open the three-dot menu on their profile card) -> Report message / Block. Blocked members can be managed in Profile -> About & privacy -> Blocked members. Reports go to the club committee, who act within 24 hours; blocked members' messages and cards are hidden. Contact: webmaster@bpj.org.uk.
e) Account deletion: Profile -> About & privacy -> Delete my account -> type DELETE. This removes the app's data for the account (profile, photo, goals, messages, sign-ups, devices, membership link).
Only one account type exists for review. Committee and leader tools are role-gated and not needed to review the member features. [If you want them reviewed, add a second demo login here.]

4. EXTERNAL SERVICES
- Auth0 (sign-in: email/password, Sign in with Apple, Google, Facebook)
- Club API at https://bpj.org.uk (own PHP/MariaDB server: schedule, updates, chat, profiles, sign-ups)
- Firebase Cloud Messaging with Apple Push Notification service (push notifications only; Analytics is off)
- The England Athletics registration data the club already holds, used once to match a member's URN and date of birth when linking. Date of birth and URN are checked on the server and not stored by the app.
No payment processors, ad networks, analytics SDKs or AI services.

5. REGIONAL DIFFERENCES
None. The app works the same in every region. It is mainly of use in the UK; parkrun/race locations listed are UK-based. [Availability set to UK only / all regions: match App Store Connect.]

6. REGULATED INDUSTRY / THIRD-PARTY MATERIAL
Not applicable. No regulated services and no protected third-party content: everything shown is the club's own or members' own content.

User-generated content: chat messages, profile photo, bio and goals are visible only to signed-in club members. Moderation: report and block in the app (reports go to the committee's inbox), committee and leaders can delete messages, rate limits and plain-text-only messages, and the committee can remove members. Privacy policy: https://bpj.org.uk/privacy-policy
```

Count it after filling the placeholders; App Store Connect truncates at 4000.

## Replying

Resubmit by replying in App Store Connect (Resolution Center -> Reply) or just updating the Notes and pressing **Resubmit to App Review**. If you add a new build for Report/Block, upload it (bump the build number, `scripts/bump-version.sh`), select it on the version page, then resubmit. Apple said this one is info-only, so with no new code you can resubmit the same build, but it is not recommended given the gap above.
