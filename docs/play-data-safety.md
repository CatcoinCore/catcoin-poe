# Google Play Data Safety declaration

The Data Safety form is filled in the Play Console (**App content → Data safety**) and
cannot be committed to the repository. This file records the answers that match what the
code actually does, so the form, [`privacy-policy.md`](../privacy-policy.md), and the app
stay consistent. **Re-check it whenever data handling changes** — a Data Safety form that
disagrees with the app or the privacy policy is itself a Play policy violation.

Derived from: `cat_poe_backend/models.py`, `routers/auth.py`, `services/fraud_detection.py`,
`cat_poe/lib/providers/auth_provider.dart`, `lib/services/api_service.dart`,
`lib/screens/signup_screen.dart`, and `cat_poe/android/app/src/main/AndroidManifest.xml`.

## Overall answers

| Question | Answer | Basis |
|---|---|---|
| Is all user data encrypted in transit? | **Yes** | API is HTTPS only; the release build sets `cleartextTrafficPermitted="false"` |
| Do you provide a way for users to request data deletion? | **Yes** (with two documented exceptions — see below) | In-app *Profile → Delete Account*, plus the account-deletion page |
| Committed to the Play Families Policy? | **No** | App is not directed at children (13+) |
| Independent security review? | **No** | None has been performed |

### What deletion does not remove

Answer the deletion question **Yes** — account deletion anonymises email, username, display
name, and social handles — but two things deliberately survive, and both are disclosed in
the privacy policy and on the account-deletion page:

- **A cryptographic identity hash is deliberately kept.** Deleting an account does not erase
  it. It exists so a deleted account cannot simply be recreated to farm rewards, and it lets
  a repeat signup be recognised without retaining the email, username, or any other detail
  behind it. It is a one-way hash, not recoverable personal data, which is why the deletion
  answer remains "Yes" — but it must stay disclosed, because a user who deletes their account
  is not left with *nothing* retained.
- **Completed blockchain payouts**, which are permanent and outside our control (see the
  Financial info note below).

## Data types to declare

"Shared" in Play's sense means transferred to a **third party**. Service providers acting
on our behalf (email delivery, hosting) do not count as sharing.

| Play category → data type | Collected | Shared | Required | Purposes | What it actually is |
|---|---|---|---|---|---|
| **Personal info** → Name | Yes | No | Optional | App functionality, Account management | `display_name` |
| **Personal info** → Email address | Yes | No | Required | App functionality, Account management, Developer communications | `email`; used for verification and password reset |
| **Personal info** → User IDs | Yes | No | Required (username) / Optional (social handles) | App functionality, Account management, Fraud prevention and security | Account UUID, 9-digit username, referral code, and any Discord / Telegram / X / Facebook / WhatsApp handle given for mission verification |
| **Financial info** → Other financial info | Yes | **See note** | Optional | App functionality | `Wallet.catcoin_address`, and `Payout` records (address, amount, status, blockchain txid) |
| **Location** → Approximate location | Yes | **Yes** | Required | App functionality, Fraud prevention and security | Country only (ISO alpha-2), derived from the public IP by third-party lookup services, falling back to device locale. **No** GPS, no location permission, never more precise than country |
| **App activity** → App interactions | Yes | No | Required | App functionality, Fraud prevention and security | Mining sessions, mission completions, game scores, leaderboard standings, in-app actions |
| **App info and performance** → Crash logs | Yes | No | Required | App functionality | Diagnostic reports emailed to the operator's inbox on unrecoverable client errors |
| **App info and performance** → Diagnostics | Yes | No | Required | App functionality | App version, platform, OS version, locale, screen, error class, HTTP status, recent-action tail |
| **Device or other IDs** → Device or other IDs | Yes | **Yes** | Required | Advertising or marketing, Fraud prevention and security, App functionality | Google Advertising ID (shared with AdMob); installation UUID sent as `X-Device-ID`; public IP address; Google Play install referrer |

### Notes on the two judgement calls

**Financial info — "Shared".** Once a payout is broadcast, the receiving address, amount,
and transaction become permanently public on the Catcoin blockchain and are readable by
any node or block explorer. That is arguably a transfer to third parties. Declaring
**Shared = Yes** is the conservative and defensible choice; confirm with whoever owns
legal sign-off. Either way, the permanence is disclosed in the privacy policy under
*Payouts and Blockchain Transactions*.

**Approximate location — "Shared".** We do not send the country anywhere, but the lookup
request goes from the user's device to third-party services (GeoJS, iplocation.net), which
necessarily see the public IP the location is derived from. Declare **Shared = Yes**.

## Explicitly NOT collected

Worth recording so future reviews do not re-litigate these:

- **Precise location** — no `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`, no
  `NSLocation*` keys, no geolocation plugin. The app never requests location permission.
- **Photos and videos** — `image_picker` is a dependency and profile images are chosen from
  the device, but they are stored locally only (`ProfileService` writes a local path) and
  there is no upload endpoint. Nothing leaves the device, so nothing is declared.
- **Contacts, Messages, Calendar, Audio, Files, Health and fitness** — no permissions, no code paths.
- **Payment info / purchase history** — the app takes no payments and has no in-app purchases.
- **Analytics identifiers beyond the advertising ID** — `firebase_core` is initialised, but
  no Analytics, Messaging, or Crashlytics package is present.

## When to revisit

Update the form *and* the privacy policy together if any of the following change:

- a new third-party SDK is added (especially analytics, attribution, or push),
- the country lookup providers change,
- profile images or any other user content start being uploaded,
- payouts move to a different chain or custody model,
- diagnostic reports start carrying additional fields.
