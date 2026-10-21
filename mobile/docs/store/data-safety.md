# Google Play: Data safety, content rating, audience, app access, account deletion

Answers to type into Play Console, in the order the Console asks. They match the code and [privacy-policy.md](privacy-policy.md) at the time of writing. If the app changes (new SDK, new data), redo this file and the Console forms, or Google may reject an update.

Items marked `[CONFIRM]` need the owner (or committee) to check, mostly things only the live Play Console can show. The big one: **account deletion must actually work in the build you submit** (see the last section).

Facts the owner has confirmed and that this file relies on: the app is for adults only (18+; the club has no members under 18, its youngest category is U20); **analytics is switched off** (the only Firebase service is Cloud Messaging); contact email `webmaster@bpj.org.uk`.

Where to find the forms: Play Console -> your app -> **Policy and programs -> App content** (older Consoles: Dashboard -> "Set up your app"). Each form below is one task there.

## 1. Data safety form

### 1.1 Overview questions

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **Yes** |
| Is all of the user data collected by your app encrypted in transit? | **Yes** (all calls to `https://bpj.org.uk/api/...` use HTTPS) |
| Do you provide a way for users to request that their data is deleted? | **Yes** |
| Deletion URL | `https://bpj.org.uk/privacy-policy#deleting-your-account-and-data` [CONFIRM the anchor works on the website; otherwise use `https://bpj.org.uk/privacy-policy`, which has a section titled "Deleting your account and data"] |
| Does the app follow the Families Policy / is it for children? | **No** (adults only: 18+) |
| Independent security review? | **No** |

What the code contains, for reference: Auth0 sign-in (`auth0_flutter`), Firebase Core + Cloud Messaging only (`firebase_core`, `firebase_messaging`), **no analytics (Google Analytics for Firebase is switched off), no crash reporter, no ads or advertising ID, no tracking SDKs**, no location, no contacts. Firebase Cloud Messaging itself processes a device push token, which is why "Device or other IDs" is ticked below. If an analytics or similar SDK is ever added, the privacy policy must be updated first and this form redone. Permissions in the release manifest are internet, post notifications, network state, wake lock, vibrate and the Firebase/biometric entries the libraries add (no camera, storage, location or contacts permissions).

### 1.2 "Collected" versus "shared" (how to read the table)

- **Collected** = the data leaves the phone to our server or to a service provider.
- **Shared** = given to a third party for *their own* purposes. Google's rules say data sent to a **service provider** that processes it only on our behalf (here Auth0 for sign-in and Google FCM for notifications) is *not* "sharing". Other club members seeing your name or photo inside the app is also not "sharing" with a third party.
- So in this app **nothing is shared**: every data type below is "Collected", **not shared**.
- **Processed ephemerally** = only held in memory to answer a request and not stored. Only the date of birth and membership number qualify.

### 1.3 Data types: answers per type

Tick the types below. Every type not listed is **not collected** (say No/untick): approximate location, precise location, phone number, address, race and ethnicity, political or religious beliefs, sexual orientation, health info, financial info (payment info, purchase history, credit info), contacts, calendar, emails or text messages (SMS), audio, videos, music, files and docs, web browsing, installed apps, in-app search history, crash logs, performance diagnostics.

For each type you tick, the Console asks the same four things: (1) collected, shared, or both; (2) processed ephemerally; (3) required or optional; (4) purposes.

| Category -> Data type | Collected / shared | Ephemeral? | Required or optional | Purposes | Notes (what it is) |
|---|---|---|---|---|---|
| **Personal info -> Name** | Collected, not shared | No | Required | App functionality; Account management | Name from the club membership record (first and last), and the name from the sign-in provider. Shown to other members as first name + initial. |
| **Personal info -> Email address** | Collected, not shared | No | Required | App functionality; Account management | Received from Auth0 / the sign-in provider (needed to sign in). Not stored in the club's app database; kept on the device and in Auth0. |
| **Personal info -> User IDs** | Collected, not shared | No | Required | App functionality; Account management | Auth0 login id and the app's member id. |
| **Personal info -> Other info** | Collected, not shared | **Yes, for date of birth and membership number** | Required (to join the members' area) | App functionality; Account management; Fraud prevention, security, and compliance | Date of birth and membership number typed once to confirm membership. Compared with the club's records on the server and **not stored by the app**. Also covers your age category from the club record. In the Console, "Other info" covers date of birth. Mark ephemeral = Yes if the Console lets you set it per type; if it is one switch for the whole type, answer **No** (the age category is stored). |
| **Photos and videos -> Photos** | Collected, not shared | No | **Optional** | App functionality | Optional profile photo (512 px square JPEG), shown to other club members. |
| **Messages -> Other in-app messages** | Collected, not shared | No | **Optional** | App functionality | Pace-group chat messages and the chat of each parkrun or race event. |
| **App activity -> Other user-generated content** | Collected, not shared | No | **Optional** | App functionality | Profile bio and goals (goals are private unless shared); the name and note of a parkrun or race event a member adds (for example a meeting point or car-share seats). |
| **App activity -> Other actions** | Collected, not shared | No | **Optional** | App functionality | Run sign-ups (going / maybe / not coming), pace group choices, leader sign-ups, which parkrun or race event the member says they are going to (members going to the same event see each other's names, D77; a chosen event, not device location), notification and reminder settings, muted chats, and when each club update was received and read (visible to the committee). |
| **Health and fitness -> Fitness info** | Collected, not shared | No | **Optional** | App functionality | Usual pace range and goals. [CONFIRM: Google may treat this as fitness info; declaring it is the safe choice. If you declare it, the Console may ask the "health apps" question, see the release checklist] |
| **Device or other IDs** | Collected, not shared | No | **Optional** | App functionality | Firebase push token (only if the user allows notifications). Also covers the IP address and device identifier (user agent) that the server writes to its log table, which is cleared of entries older than a week every night (so about a week, at most about eight days), for security and fixing faults. The host's own web-server access logs belong to the provider. [CONFIRM: host access-log retention, see privacy-policy.md checklist item 2] Purposes to tick: App functionality; Fraud prevention, security, and compliance. |

Do **not** tick: Advertising or marketing, **Analytics (the app has no analytics)**, Personalization, Developer communications (we send notifications the user turned on; Google treats those as app functionality).

### 1.4 Security practices section

| Question | Answer |
|---|---|
| Data is encrypted in transit | Yes |
| You can request that data be deleted | Yes (with the URL above) |
| Committed to follow the Play Families Policy | No (not a children's app; adults only) |
| Independent security review | No |

### 1.5 Privacy policy link (same form area)

`https://bpj.org.uk/privacy-policy` (must be live, public, not a PDF, and name the app or the club).

## 2. Content rating questionnaire (IARC)

Console -> App content -> **Content rating** -> start questionnaire. Email: `webmaster@bpj.org.uk`.

- **Category:** "Utility, Productivity, Communication, or Other". (If the Console offers only "Social" because of chat, choose that instead and answer the same.)
- Violence: **No** (all violence questions).
- Sexual content and nudity: **No**.
- Profanity or crude humour: **No**. The group chat is a user-generated feature; the content itself is not offered by the app.
- Controlled substances (drugs, alcohol, tobacco): **No**.
- Gambling, simulated gambling: **No**.
- Fear / horror: **No**.
- Does the app contain **user-generated content or user interaction** (users can communicate or share content with each other)? **Yes** (group chat, profile photo, bio and goals; visible only to club members).
- Does the app share the user's **location** with other users? **No**.
- Does it let users **purchase digital goods**? **No**.
- Does it provide **unrestricted internet access** (a browser)? **No**. Web links open in the phone's own browser.
- Is the app **ads-supported**? **No**.
- Expected result: Everyone / PEGI 3 / IARC 3+, usually with an "Users interact" notice. The rating describes the content, not who may use the app; the audience below is 18+ only. If the Console asks whether the app is for adults, answer that it is for members aged 18 and over (the club has no members under 18).

Moderation answer (the Console may ask): users can be removed by the committee (clear a profile) and messages can be deleted by authors, group leaders, run coordinators and the committee; the app has 20 messages a minute and 1000-character limits; there is no report button yet (D44). [CONFIRM: Google's User-Generated Content policy expects in-app reporting and blocking for apps with UGC. The roadmap has these as backlog. A closed club chat is a lower risk, but be ready to add "Report" and "Block" if Play review asks.]

## 3. Target audience and content

Console -> App content -> **Target audience and content**.

- **Target age groups:** tick **18 and over** only. The app is for adults: the club has no members under 18 (its youngest category is U20, which includes 18- and 19-year-olds), so do not tick any group under 18.
- **Does your app appeal to children?** **No** (it is a members' tool for a running club, plain design, no cartoon characters, no games). The app is not designed for children.
- **Designed for children / Families program:** **No**.

## 3.1 Other App content declarations

| Declaration | Answer |
|---|---|
| Ads | **No** (the app contains no ads) |
| Government app | **No** |
| Financial features | **None** (no payments, loans, banking, crypto) |
| Health | The Console asks whether the app has health features (a list: medical, fitness tracking, etc.). The app has none of the listed health features: it **does not record workouts, measure anything or give health advice**. Tick **"My app doesn't have any health features"** [CONFIRM: if the wording of the Console list includes "activity and fitness" and you think the pace range counts, tick that fitness option and answer honestly; it changes nothing else] |
| News app | No |
| COVID-19 | Not a COVID app |
| Data safety | Section 1 above |

## 4. App access (instructions for Google's reviewers)

Console -> App content -> **App access** -> "All or some functionality is restricted" -> add instructions.

Why: the app is for members only. After signing in, a new user is stopped on a link screen asking for a membership number and date of birth that match the club's membership records. Reviewers do not have either, so give them a test account.

### 4.1 What to paste into the Console

```
This app is for members of Black Pear Joggers, a running club. After signing in you must link your login to a club membership.

Sign in:
  1. Open the app and tap "Sign in".
  2. On the Auth0 page choose "Log in with email" (do not use Google or Facebook).
  3. Email: [reviewer test email]
     Password: [reviewer test password]

Link the membership (first sign-in only):
  4. On the "Link your membership" screen enter
     England Athletics URN: [test URN]
     Date of birth: [test date of birth] (tap the field and pick the date in the calendar)
  5. Tap "Find me", then "That's me".

You can now see: Updates, Runs (schedule and pace groups), Inbox and Profile.
This test account has no special roles. Contact webmaster@bpj.org.uk if the credentials fail.
```

(Labels checked against `lib/features/auth/ui/sign_in_screen.dart` and `lib/features/membership/ui/link_screen.dart` on 2026-10-12; recheck if those screens change. The "Log in with email" wording belongs to the Auth0 page, check how your Universal Login page words it.)

### 4.2 How to create the test account safely

Do this **once**, a few days before submitting. Never use a real member's details.

1. **Test login in Auth0.** Dashboard -> User Management -> Users -> Create User, connection "Username-Password-Authentication". Use an email address the club owns (for example a plus-address on the committee mailbox), a long random password, and put the password in the club's password manager, not in chat or git. Mark the user as email-verified.
2. **Test athlete in the club's data.** The link check looks for a row in `athletes` with a matching `urn` and `dob`, and the account is "active" only if that URN has a `payments` row with `paymentStatus = 'Paid'` or a `memberships` row with `competitiveRegStatus = 'Registered'`. A lapsed member sees the link screen again. Ask the developer to add:
   - an `athletes` row with a made-up name such as "Play Reviewer", a URN that does not belong to any real person, and a made-up date of birth;
   - a `payments` row for that URN, `paymentStatus = 'Paid'`, `membershipType = 'basic'`, a unique `reference` such as `PLAY-REVIEW-1`.
   [CONFIRM: the nightly sync from England Athletics and the payments sync do not delete or overwrite these rows; check after the first night.] If the sync removes them, re-add before each review or keep the review short.
3. **Pick a believable but safe URN.** Use a number outside the EA range in use (for example the next unused number in `athletes`), not a real URN.
4. **Try it yourself.** Sign in on a spare phone with that login and link. Confirm that Runs shows upcoming runs (if there are none, add one ad-hoc run) and that the chat opens (join a pace group first).
5. **After approval**, change the password or delete the test login and test rows. Delete using the app's own "Delete my account" first (it also proves deletion works), then remove the `athletes` and `payments` test rows by hand.

The reviewer will not have committee or admin rights. That is fine. If you want them to see the post-update screen, give the test member the `committee` role: `php artisan app:member-role 1 <athletes.id> committee` (remove with `--remove` afterwards).

## 5. Account deletion form answers

Console -> App content -> **Data deletion** (named "Account deletion" in some Consoles).

| Question | Answer |
|---|---|
| Does your app allow users to create an account? | **Yes** (users create a login with Auth0, with Google, Facebook or email, and link it to a membership) |
| In-app deletion path | Profile tab -> About & privacy -> Delete my account (the user types `DELETE` to confirm) |
| URL for requesting account and data deletion | `https://bpj.org.uk/privacy-policy#deleting-your-account-and-data` [CONFIRM anchor; otherwise the policy URL] |
| Can users request deletion of **some** data without deleting the account? | **Yes**: remove the profile photo, bio and goals in Profile -> My profile card; delete own chat messages; turn off notifications. |
| Data deleted when the account is deleted | The login's link to the membership, push tokens, notification inbox and settings, running preferences and reminder choices, profile photo/bio/goals, chat messages (pace-group and event chats) and chat settings, run sign-ups, parkrun and race event sign-ups and leader sign-ups, link-attempt records. |
| Data kept after deletion, and why | The website login and the sign-in provider account (shared with the website; ask the club to remove); the club's own membership, payment and results records (the club's records, not the app's); club updates written by committee members (kept without the author name); notifications already delivered to other members that mention the deleted member; a one-line log ("removed member <id> of club <id>": ids only, no name or email) in the app's database log table (cleared of entries older than a week every night, so about a week) and in the club's private Slack log channel [CONFIRM: Slack retention, privacy-policy.md checklist item 9]; the host's own web-server access logs [CONFIRM: host retention]; copies in backups until the host's next backup replaces the old one. |
| Retention period for kept data | See the policy: database logs about a week (at most about eight days); backups are replaced by the next backup (the host keeps only the latest one; no fixed number of days); Slack and host access logs [CONFIRM]. |

### 5.1 It must be true

Before you submit (checklist item): on production, with a throwaway account, run Profile -> About & privacy -> Delete my account. Check that the app signs out, the member row is gone (or the logins are), and signing in again goes back to the link screen. Also try the email route once with a second throwaway account.

The `DELETE /app/account` endpoint and the About & privacy screen now exist in the code (api-contract.md "Phase 7b", D72, D75, ROADMAP 7b: built and tested). What is still to prove is that it works against the **production** API with `2026_10_posts_author_nullable.sql` applied. Do not submit until it does.
