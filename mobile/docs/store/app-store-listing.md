# Apple App Store: listing, privacy labels, age rating, review notes

Answers to type into **App Store Connect** (https://appstoreconnect.apple.com) for BPJ, `uk.org.bpj.app`. They reuse the Play material ([play-listing.md](play-listing.md), [data-safety.md](data-safety.md)) so the two stores say the same thing. Items marked `[CONFIRM]` need the owner. Roadmap: [Phase 7c](../ROADMAP.md). Sign in with Apple: D131 and [setup.md](../setup.md#sign-in-with-apple-phase-7c).

## 0. Project fixes before you archive (1 and 2 done 2026-11-11, 3 is your call)

1. **Export compliance key (done).** Added to `ios/Runner/Info.plist`:
   ```xml
   <key>ITSAppUsesNonExemptEncryption</key>
   <false/>
   ```
   The app only uses HTTPS and the system's own encryption, which is exempt. Without the key, App Store Connect asks the export-compliance question on every build.
2. **Privacy manifest (done).** `ios/Runner/PrivacyInfo.xcprivacy` is added to the Runner target: tracking = No, no tracking domains, no collected-data entries and no required-reason APIs of the app's own (the app's Swift code uses none; Flutter and the plugins ship their own manifests). App Store Connect emails a warning after upload if a required-reason API is missing, so check your inbox after the first upload and add it here if asked.
3. **iPad.** `TARGETED_DEVICE_FAMILY = "1,2"` means iPad is supported, so Apple demands iPad screenshots (13-inch, 2064 x 2752) and the app has to look right on iPad. The app is phone-first, so for 1.0 set it to **iPhone only** (`1`) in Xcode -> Runner -> General -> Supported Destinations. iPad users can still install it in compatibility mode. `[CONFIRM]` your choice.

The entitlements file says `aps-environment = development`. That is normal: Xcode switches it to `production` when you archive with distribution signing. Check it in the build's entitlements after the first upload if push does not arrive on TestFlight.

## 1. Create the app record

App Store Connect -> Apps -> **+ New App**.

| Field | Value |
|---|---|
| Platform | iOS |
| Name (max 30, unique across the whole store) | **BPJ** (3 chars). If taken, `BPJ - Black Pear Joggers` (24), then `Black Pear Joggers`. |
| Primary language | English (U.K.) |
| Bundle ID | `uk.org.bpj.app` (pick it from the list; it appears once the App ID exists in the developer portal) |
| SKU | `bpj-app-ios` (private, never shown, cannot change) |
| User access | Full access |

**Seller name.** The name next to "Developer" on the store is the account holder's legal name. An individual account shows a personal name; showing "Black Pear Joggers" needs an organisation account (D-U-N-S number). `[CONFIRM]` which kind of account was paid for on 2026-11-06. This cannot be changed to a club name afterwards without a new account type.

## 2. App Information

| Field | Value |
|---|---|
| Subtitle (max 30) | `Club runs, groups and chat` (26) |
| Category: primary | **Sports** |
| Category: secondary | Health & Fitness (optional; or leave blank, or Social Networking) |
| Content rights | "Does your app contain, show, or access third-party content?" **No.** (Everything shown is the club's or its members' own. Map links open in the browser.) |
| Age rating | See section 5 |
| License agreement | Apple's standard |

## 3. Pricing and availability

- **Price:** Free (price tier 0). A free app needs no banking or tax forms.
- **Availability:** United Kingdom only is the honest choice (a Worcester club's members' app). Every country is fine too, but then reviewers and strangers in other storefronts can find it. Choose UK, or all.
- **Pre-orders:** No. **Apple Silicon Macs / Vision Pro:** switch "Make this app available" off for both (the app was not built or tested for them).
- **Distribution method:** Public App Store.

## 4. Version 1.0 page (the "Prepare for Submission" screen)

### Promotional text (max 170, can be changed any time without a review)

```
Runs, pace groups, reminders and chat for Black Pear Joggers members. Tell the leaders you're coming and never miss club news.
```
(126)

### Description (max 4000)

Use the Play full description from [play-listing.md](play-listing.md) with these changes (Apple rejects references to other platforms, and wants wording to match what the app does on iOS):

- Keep "Black Pear Joggers membership is needed to use the app" and the sign-in sentence, but change it to `You sign in with Apple, Google, Facebook or your email address` (Sign in with Apple only once it is live in Auth0; D131).
- Under REMINDERS, "buttons right in the notification" works on iOS (action category) `[CONFIRM after a real-device check]`; otherwise delete that bullet.
- Delete "PARKRUN AND RACES" if Phase 8 is not deployed on production.
- Keep "No adverts, no tracking, no location." (Matches the privacy label in section 6.)

### Keywords (max 100 characters, comma-separated, no spaces after commas)

```
running,club,parkrun,pace,group,chat,runs,Worcester,jogging,leaders,members,reminders,race
```
(90; don't repeat the app name or category words, Apple already indexes them)

### What's New (max 4000; the first release shows it too)

```
First release for club members.
- Club updates and run reminders with push notifications
- Run schedule, pace groups and leader sign-up
- Group chat and member profile cards
```

### URLs and text

| Field | Value |
|---|---|
| Support URL (required) | https://bpj.org.uk (or a `/contact` page if the site has one). It must be a live page with a way to reach you. `[CONFIRM]` |
| Marketing URL (optional) | https://bpj.org.uk |
| Privacy Policy URL (required) | https://bpj.org.uk/privacy-policy (live, public, names the club or app; resolve the `[CONFIRM]` markers in [privacy-policy.md](privacy-policy.md) first) |
| Copyright | `2026 Black Pear Joggers` |
| Version | `1.0.0` (from `pubspec.yaml`; the build number after the `+` is the build) |

### Screenshots (required)

| Device | Size (portrait) | Count |
|---|---|---|
| **iPhone 6.9"** (iPhone 16/17 Pro Max) | 1320 x 2868 (1290 x 2796 also accepted) | 3 to 10 |
| iPhone 6.5" | Optional now; Apple scales the 6.9" ones down. | |
| iPad 13" | 2064 x 2752, **only if the app supports iPad** (section 0, item 3) | |

Use the shopping list in [play-listing.md](play-listing.md) (updates, runs, run page, pick-your-pace sheet, chat, profile card, leader tools). Capture them on an iPhone 16/17 Pro Max simulator (Cmd+S in Simulator) with a test account and invented members, no real faces or names. No device frames that cover the app. A screenshot of the reminder notification is not possible in the simulator, so skip it or use a real phone.

### Build

Section 7 below. Pick the uploaded build in the "Build" box once it has finished processing (10 to 30 minutes after upload).

### App Review Information

| Field | Value |
|---|---|
| Sign-in required | **Yes** |
| User name / password | The reviewer test login from [data-safety.md](data-safety.md) section 4.2 (email + password). The same one works for Apple and Google. Do not use a real member. |
| Contact | Your name, phone, and `webmaster@bpj.org.uk` (Apple phones if they are stuck) |
| Notes | Paste the block below |

```
BPJ is the members' app of Black Pear Joggers, a running club in Worcester, UK. It is free and has no in-app purchases, ads or tracking.

Because the club's data is members-only, the app needs a membership. Nothing is for sale in the app; membership is arranged on the club's website.

To review:
1. Tap "Sign in". On the login page choose "Log in with email" (or "Continue with Apple" / Google / Facebook) and use the demo login above.
2. On "Link your membership" enter URN [test URN] and date of birth [test date of birth], tap "Find me", then "That's me".
3. You can then see Updates, Runs (schedule and pace groups), Inbox and Profile. Open a run, tap "I'm coming", pick a pace group, and open that group's chat.

Account deletion: Profile -> About & privacy -> Delete my account (type DELETE to confirm).
Push notifications (Firebase Cloud Messaging) are used for club updates and run reminders, and are optional.
Camera and photos are used only to choose an optional profile photo.
User-generated content: group chat, profile photo, bio and goals are visible only to signed-in club members. [Describe the Report/Block feature here once built: see section 9.]
```

**Version release:** choose "Manually release this version" for 1.0 so you control the day it goes live after approval.

## 5. Age rating

App Store Connect -> App Information -> **Age Rating -> Edit**. The questionnaire has been revised, so read each question, but the truthful answers are:

- Violence, sexual content or nudity, profanity or crude humour, horror or fear, mature or suggestive themes, alcohol, tobacco or drug references, medical or treatment information, gambling or contests: **None** for each.
- User-generated content / **messaging and chat**: **Yes** (pace-group and event chat, profile photo, bio, goals; members only).
- Unrestricted web access: **No** (links open in Safari).
- Does the app have parental controls or age assurance: **No**.
- Expected result: 4+ (or 12+ because of user-generated content, depending on the current questionnaire). Whatever it says, accept it.

Apple's rating describes content. The club's own rule is 18+ members only. You cannot restrict the audience in App Store Connect; the membership link screen is the gate.

## 6. App Privacy (the "nutrition labels")

App Store Connect -> **App Privacy** -> Get Started. Same facts as [data-safety.md](data-safety.md) section 1.3. All of it is **linked to the user's identity**, and **none is used for tracking** (no data is combined with other companies' data for advertising, and there is no tracking SDK).

- **Do you or your third-party partners collect data from this app?** Yes.
- Privacy policy URL: https://bpj.org.uk/privacy-policy.
- **Tracking:** No. This means no App Tracking Transparency prompt is needed (the app has none).

| Apple category -> type | Linked to user | Tracking | Purposes (tick only these) | Matches Play row |
|---|---|---|---|---|
| Contact Info -> **Name** | Yes | No | App Functionality | Name |
| Contact Info -> **Email Address** | Yes | No | App Functionality | Email address (held by Auth0; sign-in) |
| Identifiers -> **User ID** | Yes | No | App Functionality | User IDs |
| Identifiers -> **Device ID** | Yes | No | App Functionality | Device or other IDs (push token) |
| User Content -> **Photos or Videos** | Yes | No | App Functionality | Photos (optional profile photo) |
| User Content -> **Other User Content** | Yes | No | App Functionality | Chat messages, bio, goals, comments, event notes |
| Usage Data -> **Product Interaction** | Yes | No | App Functionality | Run sign-ups, pace choices, read receipts, reminder settings |
| Health & Fitness -> **Fitness** | Yes | No | App Functionality | Usual pace range and goals `[CONFIRM: declared on Play for safety; keep the two stores the same]` |
| Other Data -> **Other Data Types** | Yes | No | App Functionality | Date of birth and membership number: typed once, checked on the server, **not stored** (Apple counts data "collected" only if kept beyond answering the request; leave unticked if you are happy with that reading, the safe choice is to tick it) `[CONFIRM]` |

Not collected (answer "No" / untick): Location (any), Contacts, Browsing History, Search History, Purchases, Financial Info, Sensitive Info, Diagnostics (crash data, performance data: there is no crash reporter or analytics), Advertising Data. Firebase Analytics is off; if it is ever turned on, this label, the Play form and the privacy policy all change first.

After saving, press **Publish** on the App Privacy page. It is separate from submitting the version.

## 7. Building and uploading

Needs a Mac with Xcode (the project's `DEVELOPMENT_TEAM` is set; signing is automatic).

```bash
cd mobile
scripts/bump-version.sh
flutter build ipa --release --dart-define-from-file=config/prod.json
```

Output: `build/ios/ipa/*.ipa`. Upload with the **Transporter** app (Mac App Store, free; drag the `.ipa` in) or `xcrun altool`. App Store Connect emails when processing finishes or fails.

- Run `flutter analyze` and `flutter test` first, and check `config/prod.json` points at production.
- The build number must be higher than every earlier upload **for version 1.0.0** (the same `+N` in `pubspec.yaml` as Android; bump for every upload, even a failed one).
- **TestFlight first.** The build appears under TestFlight after processing. Add yourself as an **internal tester** (up to 100 App Store Connect users, no review), install on a real iPhone and run the smoke test in [release-checklist.md](release-checklist.md) section G, and confirm **push on a real iPhone** (ROADMAP Phase 7c still open). External testers (club members, up to 10,000) need a short Beta App Review for the first build.
- Then press **Add for Review** / **Submit for Review** on the version page.

## 8. Before you press Submit

- [ ] Sign in with Apple works end to end on an iPhone and Android (D131; ROADMAP 7c checklist). It is guideline 4.8: Google and Facebook are offered, so the Apple button must be there.
- [ ] Account deletion proven against **production** (release-checklist.md section G), because Apple requires it in the app (guideline 5.1.1(v)).
- [ ] Reviewer demo login exists, links, and the test athlete row survives the nightly sync.
- [ ] Privacy policy page is live; the support URL works.
- [ ] Section 0 items done (export key, privacy manifest, device family).
- [ ] Push tested on a real iPhone from a TestFlight build.
- [ ] Screenshots uploaded; description and screenshots only claim what the iOS build does.
- [ ] App Privacy published.

## 9. The biggest rejection risk: user-generated content

Apple guideline **1.2** is stricter than Play. An app with chat, photos and bios must have: a way to **report** offensive content, a way to **block** abusive users, a method to filter content, and published contact details. The app today has message deletion and committee removal, but **no Report or Block** ([data-safety.md](data-safety.md) section 2 notes the same gap; D44, roadmap backlog). A closed club app is lower risk, but reviewers do check for it and it is the most common reason chat apps are bounced.

Recommended before submitting: build a small **Report** (message, profile) that notifies the committee, and **Block** (hide that member's messages and profile for me), and mention both in the review notes. That is a task of its own; ask for it when you are ready. If you submit without, say in the notes that the club is members-only, the committee moderates, and give the contact email, and be ready for a rejection asking for it.

## 10. After approval

Choose the release date, release the version, and update [ROADMAP.md](../ROADMAP.md) Phase 7c. Later updates: bump the build number, upload, pick the build on a new version page, add "What's New", submit. Use **phased release** for any change you are nervous about.
