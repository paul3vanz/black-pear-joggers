# Privacy policy: BPJ app (DRAFT)

This is a draft for https://bpj.org.uk/privacy-policy. Everything from the line "START OF PUBLISHED TEXT" down is meant to be published. The part above it is for the owner and committee only. Delete it before publishing.

## Owner review checklist (do not publish)

Answered by the owner and already applied below: contact email (`webmaster@bpj.org.uk`), adults-only app (the club has no members under 18), analytics switched off, what the logs and the deletion log line are (read from the code), backups (the host keeps only the latest backup).

Still open. Search this file for `[CONFIRM` and `[date]`, resolve each, then delete the marker:

1. **Legal status and controller.** What "Black Pear Joggers" is in law, who is the data controller, and whether the club is registered with the ICO or exempt (https://ico.org.uk/for-organisations/data-protection-fee/self-assessment/). Intro paragraph.
2. **Hosting provider.** Name and country of the host (the API is on shared PHP hosting, D60), and **how long the host keeps its own web-server access logs** (these hold IP addresses). Sections 5, 6 and 7.
3. **Auth0.** The tenant is `blackpearjoggers.us.auth0.com`, which suggests the US region. Check the region in the Auth0 dashboard, the international transfer mechanism (UK-US data bridge or standard contractual clauses), and that email-and-password sign-ups are stored only in Auth0. Sections 5 and 6.
4. **Does bpj.org.uk already have a general privacy policy?** This page may replace it or sit beside it. The membership records the app checks (name, membership number, date of birth) come from the club's membership system and England Athletics and should be covered by the club's main policy. Section 7 and the "What is not deleted" list.
5. **Legal bases wording** in the section 2 table (legitimate interests, consent, performing the membership arrangement). Agree it with the committee.
6. **"No health information in goals" wording.** The Goals box is free text, so people could type health details. The text asks them not to. Section 2.
7. **Chat visibility wording.** The committee and administrators can read, post in and remove messages in every chat (D39), and the policy says so in section 4. Confirm the committee is happy to say it publicly.
8. **Chat, inbox and run sign-up retention.** None of these is deleted automatically while an account exists. Decide whether to promise a period (for example 12 months); that needs a job in the API first. Section 7.
9. **Slack.** The API's default log setup also sends every log line to private channels in the club's Slack workspace (see section 2 "Technical logs"). Slack's own retention for those messages is not controlled by the app. Confirm the retention of that workspace (or switch the Slack log channels off for the production API) and keep the wording in sections 2, 5, 7 and the deletion section true. Also confirm the production `.env` does not set `LOG_CHANNEL` to something other than the default.
10. **Before publishing:** account deletion is built and tested (D72, D75, ROADMAP 7b) but must be checked against production with a throwaway account first (release-checklist section G). Do not publish or submit to Google Play until it works there.

Other open items live in [data-safety.md](data-safety.md) (Play forms that need the live Console, user-generated-content Report/Block expectation) and [release-checklist.md](release-checklist.md).

---

START OF PUBLISHED TEXT

# Privacy policy: Black Pear Joggers app

**Last updated:** [date]

This policy explains what the Black Pear Joggers app ("the app", app id `uk.org.bpj.app`) does with your personal information. We are Black Pear Joggers, a running club in Worcester (website: https://bpj.org.uk). We are the "controller" of your information under the UK GDPR and the Data Protection Act 2018. [CONFIRM: legal status of the club and ICO registration]

**Contact:** webmaster@bpj.org.uk. You can email us about anything in this policy, including to see, correct or delete your information.

## 1. The short version

- The app is for **members of Black Pear Joggers aged 18 or over**. You sign in, then prove you are a member with your membership number and date of birth.
- We keep only what the app needs: who you are in the club's records, your run sign-ups, the parkruns and races you say you are going to, your messages in chats, your notification settings, and (if you choose) a photo, short bio and goals.
- Your **date of birth and membership number are used once to check it is you. The app does not copy them into its own data.** They stay in the club's membership records, where they already were.
- There are **no adverts**, no advertising IDs, **no analytics** and no location tracking in the app. The only Google/Firebase service the app uses is Firebase Cloud Messaging, which delivers push notifications. We do not sell your information.
- You can **delete your account in the app** (Profile -> About & privacy -> Delete my account) or by emailing us. See "Deleting your account and data" below.

## 2. What we collect, why, and our legal basis

[CONFIRM: committee agrees the legal bases in the last column]

| Information | Where it comes from | Why we use it | Legal basis |
|---|---|---|---|
| **Sign-in identity**: the account you sign in with (Google, Facebook, or email and password), and a unique login ID. Your name, email address and profile picture from that provider are also received. | You, through Auth0 and the provider you pick | To sign you in and keep you signed in. | Our legitimate interests in running a members' service securely (or performing our membership arrangement with you) |
| **Membership check**: your membership number and date of birth, which you type once. | You | To check you are a current club member and link your login to your membership record. They are compared with the club's membership records and **are not stored by the app**. We store only that a link attempt happened (your login ID, the club, whether it worked, and the time) to stop guessing: five failed tries in an hour are blocked. | Legitimate interests (keeping members' information safe from other people) |
| **Name and membership status**: your first and last name, age category (for example V40 or U20) and whether your membership is active, taken from the club's membership records. | Club membership records | To show you your own details and to show your name (first name and the first letter of your surname, for example "Sam B.") to other members where described in section 4. | Legitimate interests / performing our membership arrangement |
| **Gender and age category**: from your club membership record. | Club membership records | Your gender and age category are used to show the standards for your category. | Legitimate interests / performing our membership arrangement |
| **Profile photo, bio and goals** (all optional). | You | To let members know who is leading or running with them. The photo and bio are shown to other club members. Goals are private unless you tick "Share my goals with other members". | **Consent** (you choose to add them and can remove them at any time) |
| **Run sign-ups**: which runs you are coming to or might come to, the pace group you join, your pace for a run, and any group you offer to lead. | You | To organise runs and pace groups, tell leaders how many are coming, and let you see your sign-ups. | Legitimate interests (running club sessions) |
| **parkrun and race events**: the parkruns and races you add to a Saturday or a club race, whether you say you are going or might go, and any note you write on an event (for example a meeting point or spare car seats). | You | To show how many club members are going to each event, to let people who are going to the same event see each other so they can meet up and share lifts, and to give each event its own chat. | Legitimate interests (running club activities) |
| **Your running preferences**: miles or kilometres, your usual pace range, which weekly runs you want reminders for. | You | To show paces in your units, suggest groups, and send the right reminders. | Legitimate interests |
| **Chat messages**: what you write in a pace group's chat or an event's chat, with your name and time. | You | So people in the same run group or event can talk (running late, where to meet, who has a spare seat). | Legitimate interests |
| **Notifications**: a copy of each notification sent to you (your inbox), your notification settings, and which chats you muted. | Generated by the app and the club | To deliver club updates, run reminders and chat alerts, and so you can read what you missed. | Legitimate interests |
| **Push notification token**: a code that identifies your phone to Google's Firebase Cloud Messaging service, plus your app version and the phone type (Android or iOS). | Your phone | To send push notifications to your phone. Only if you allow notifications. | Legitimate interests / your consent (you can turn notifications off in your phone settings) |
| **Technical logs**: when the app's server records an event or error it writes a log entry with the time, the message, your internet address (IP address) and the identifier your app or browser sends. See "Technical logs" just below. | Automatic | To keep the service running and fix faults. | Legitimate interests |
| **Whether you have received and read club updates**: when each update reached your phone and when you opened it and read it. | Your phone | So the committee can tell whether an important message has got through. This is always on and can't be turned off in the app. | Legitimate interests |
| **Comments on club updates**: what you write under an update, with your name and time. | You | So members can ask questions about news and the committee can answer. | Legitimate interests |
| **Club updates you write** (committee only): the posts you publish. | Committee members | To tell members about club news. | Legitimate interests |

We do **not** collect your location, contacts, calendar, health data, payment details or advertising ID. The parkrun or race you pick is something you choose from a list or type in; the app does not track where your phone is. The app asks only for permission to show notifications. If you pick a profile photo, you choose it from your gallery or camera yourself; the app does not get blanket access to your photos or camera. Photos are shrunk to a small square on your phone before they are uploaded, and any location tag in the photo is removed in that process.

We ask that you do not put health information or other sensitive details in your bio, goals, event notes or chat messages. [CONFIRM: committee happy with this wording]

**No analytics.** The app does not use Google Analytics or any other analytics, advertising or tracking tool. The only Firebase service in the app is Firebase Cloud Messaging (push notifications), which processes your phone's push token as described above. If we ever add analytics or anything similar, we will update this policy first and tell members before it goes live.

**Technical logs.** The app's server (not your phone) keeps logs of events and errors, for example a failed push notification or a server fault. By default:
- Log entries are written to a table in our database. Each entry holds the time, the message, the IP address that made the request and the app or browser identifier (user agent). Entries older than one week are deleted by a job that runs every night, so an entry lives for about a week (at most about eight days).
- The same log messages are also posted to private channels in the club's Slack workspace so the webmaster can see problems. Those messages contain the log text and level, not the IP address or the app identifier. [CONFIRM: retention of the club's Slack workspace]
- The only account event we log is a deletion (see below), and that line holds only a member number and a club number.
- The app keeps a short on-device diagnostics log (errors and request outcomes, no content or personal details); it stays on your phone unless you choose to copy it and send it to us.
- Our web hosting provider's web server may also keep its own access logs (which normally include IP addresses and the pages requested). We do not control those; the provider decides how long it keeps them. [CONFIRM: the provider's access-log retention]

## 3. What stays on your phone

The app keeps a copy of your club updates, runs, groups, events, chats, profile and settings on your phone so it works without a signal. Your sign-in credentials are kept in your phone's secure storage. If you sign out, or delete your account, the app removes this data from the phone.

## 4. Who can see what

| Information | Who can see it |
|---|---|
| Your name (first name and surname initial, e.g. "Sam B.") | Other club members, where you lead a group, coordinate a run, post a club update, or write in a chat. Members who never post and aren't leading anything are shown only as counts, except as described below for events. |
| Your photo and bio (if you add them) | Other active members of the club. |
| Your goals | Only you, unless you tick "Share my goals with other members", then other club members. The committee cannot see private goals in the app. |
| That you are coming to a run, and which group | You; the leaders of that group, the run's coordinator and the committee see names. Other members see only how many are coming and an anonymous spread of paces. |
| That you are going (or might go) to a parkrun or race event | **Other members who are going to the same event see your name and whether you are going or maybe**, so you can meet up and share lifts. Members who are not in that event see only how many are going. Leaders, the run's coordinator and the committee keep their usual view. |
| An event you add, and any note you write on it | The event's name and note are visible to club members who open that Saturday's runs or that race. Keep notes to things like a meeting point. |
| That you are leading a group | All club members. Leader names are public to members. |
| Chat messages (pace-group chats and event chats) | Everyone in that chat (for a pace group: its leaders, members who joined the group and the run coordinator; for an event: the members who are going or might go to it) and the committee and administrators, who can read, post in and remove messages in every chat for moderation. [CONFIRM: committee happy to say this publicly (D39)] Pace-group chats close 12 hours after the run ends and stay readable afterwards while the group exists. Messages can be deleted by their author, the chat's leaders, the run's coordinator and the committee. |
| Whether you have received and read a club update | The committee and administrators, with your name. Other members never see it. |
| Comments on a club update | Everyone the update is for (usually all members) and the committee and administrators, who can also delete comments and close comments on an update. Your name shows as first name and surname initial. |
| Your pace range and units | Used to match you with groups and notify leaders. Leaders, the run coordinator and the committee see your pace next to your name only for runs you have said you are coming to. Other members see an anonymous spread. |
| Your membership number and date of birth | The app does not store or show them. They stay in the club's membership records, visible to the people who already have access to those records. |
| Your email address | Held by Auth0 (and your sign-in provider). It is not stored in the club's app database and not shown to other members. |

Committee members and administrators can also see members' names and roles in the app's member tools, and can clear a member's photo, bio and goals if they break the club's rules.

## 5. Who we share it with (our suppliers)

We use a few companies to run the app. They handle information only for us, to provide their service.

| Supplier | What they do | Information involved |
|---|---|---|
| **Auth0 (Okta)** | Runs the sign-in. Also used by the club's website. | Your login ID, name, email, sign-in method and picture from your sign-in provider; your password if you use email sign-in. May be processed outside the UK. [CONFIRM: region and transfer mechanism] |
| **Google (Firebase Cloud Messaging)** | Delivers push notifications to your phone. This is the only Google/Firebase service in the app. | Your push token and the text of each notification (for example a run reminder or the start of a chat message). Google may process this outside the UK. |
| **Our web hosting provider** [CONFIRM: name and country] | Hosts the club's app server and database. | All the information the app stores about you (sections 2 and 4), plus the host's own web-server logs. |
| **Slack** | The club's workspace receives the server's log messages for the webmaster (see "Technical logs" in section 2). | Log messages only: for example the time, a short technical message, and in the case of a deletion a member number and club number. |
| **Google, Facebook (if you choose them to sign in)** | They sign you in. | Whatever they hold about you; see their own policies. |

We do not use advertising or analytics companies. We do not sell or rent your information. We may disclose information if the law requires it.

## 6. Where your information is stored, and transfers

The app's own data is stored on our hosting provider's servers [CONFIRM: country]. Auth0, Google and Slack may process information in the United States or elsewhere outside the UK; where they do, they rely on legal safeguards such as the UK-US data bridge or standard contractual clauses (the UK addendum). [CONFIRM: Auth0 region and transfer mechanism]

## 7. How long we keep it

- **While you have an account:** the information in section 2 is kept so the app keeps working.
- **If you delete your account:** it is removed as described in "Deleting your account and data" below.
- **Technical logs in our database:** entries older than one week are deleted by a nightly job, so about a week (at most about eight days). The log copies in the club's Slack workspace are kept as long as that workspace keeps them. [CONFIRM: Slack retention] The host's own web-server access logs are kept for as long as the host decides. [CONFIRM: host access-log retention]
- **Chat messages, inbox notifications, event and run sign-ups:** these are not deleted automatically while you have an account. [CONFIRM: committee to agree a period, for example 12 months, and have it built] A message deleted in the app is hidden straight away. Deleting your account removes the messages you wrote.
- **Failed and successful membership-link records:** kept until you delete your account.
- **Backups:** our host keeps only its latest backup of the database, and it is kept until the next backup replaces it. So information you delete in the app disappears from our backups when the next backup replaces the old one.
- **Your club membership records** (kept by the club outside the app, under the club's main privacy policy) are not affected by deleting the app account. [CONFIRM: whether the club already has a general privacy policy on the website]

## 8. Your rights

Under UK data protection law you can ask us to: see the information we hold about you; correct it; delete it; restrict or object to how we use it; and receive it in a portable form. Where we rely on your consent (photo, bio, goals), you can withdraw it at any time by removing them in the app (Profile -> My profile card) with no effect on anything done earlier. To use any right, email webmaster@bpj.org.uk. We will answer within one month.

If you are unhappy with how we handle your information, please tell us first. You can also complain to the Information Commissioner's Office (ICO): https://ico.org.uk/make-a-complaint/ or 0303 123 1113.

## Deleting your account and data

You can delete your app account in two ways.

**A. In the app (quickest)**
1. Open the app and go to the **Profile** tab.
2. Tap **About & privacy**.
3. Tap **Delete my account**, read the explanation, type `DELETE` to confirm, and tap the delete button. You need an internet connection. The app then signs you out and removes its data from your phone.

**B. By contacting the club**
Email webmaster@bpj.org.uk from the address you use with the club and say you want your BPJ app account and data deleted. Tell us which sign-in you used (Google, Facebook or email) and your name as it appears in the club. We may ask you to confirm it is you. We will do it within one month.

**What is deleted** (everything the app itself holds about you):
- the link between your sign-in and your club membership (to come back you must link again with your membership number and date of birth);
- your push notification tokens;
- your notification inbox and notification settings;
- your running preferences and reminder choices;
- your profile photo, bio and goals;
- the chat messages you wrote (in pace-group chats and event chats) and your chat mute settings;
- your run sign-ups (going, maybe, not coming), your parkrun and race event sign-ups, pace choices, and group leader sign-ups;
- records of your membership-link attempts.

**What is not deleted**
- **Your website login and sign-in provider account.** Your Auth0 login is shared with the website, and Google and Facebook accounts are yours. Deleting the app account does not close them. Ask us if you want your website login removed too.
- **Your club membership and records** (England Athletics registration, payments and results held by the club). These belong to the club and are covered by the club's main privacy policy. Leaving the app does not end your membership.
- **Club updates you wrote** (committee members only): the posts stay but no longer show you as the author.
- **Things that stay but no longer point to you:** runs you coordinated lose their coordinator; events and groups you created stay, with no creator recorded. Events you added stay for other members who are going to them.
- **Notifications already delivered to other members** that mention you (for example a chat alert showing your name and the start of a message) stay in their inboxes.
- **A short log line** recording that an account was deleted. It says only "removed member [member number] of club [club number]": no name, email or other detail. It goes to the app's log table in our database, which is cleared of entries older than a week every night (so it lives for about a week, at most about eight days), and to the club's private Slack log channel. [CONFIRM: Slack retention]
- If you are the **only administrator** of the club's app, deletion is blocked until another administrator is named, so the club is not left without one.
- **If you signed in with more than one login** (for example Google on the website and Facebook in the app), deleting from one login removes only that login and its phones; your data stays while another login is still linked. Delete from each login, or ask us to remove everything.
- **Backups.** Our host keeps only its latest backup, and the next backup replaces it, so deleted data leaves the backups when the next backup is made.

## 9. Children

The app is for club members aged **18 or over**. The club has no members under 18 and the app is not designed for children or directed at them. We do not knowingly collect information from anyone under 18. If we learn that we have, we delete it. If you believe someone under 18 has an account, email webmaster@bpj.org.uk and we will delete it.

## 10. Security

All traffic between the app and our servers uses HTTPS. Sign-in is handled by Auth0 and the app never sees your password. Credentials are stored in your phone's secure storage. Access to member information is limited by role (member, leader, committee, administrator). No system is perfectly secure; if there is a breach that puts you at risk we will tell you and the ICO as the law requires.

## 11. Changes to this policy

If we change what the app does with your information (for example, if we add analytics or any similar tool) we will update this page and the date at the top **before the change goes live**, and tell members through the app for any important change.

## 12. Contact

Black Pear Joggers, Worcester. Email: webmaster@bpj.org.uk. Website: https://bpj.org.uk
