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
| **Personal info** → User IDs | Yes | No | Required | App functionality, Account management, Fraud prevention and security | Account UUID, 9-digit username, referral code, and any Discord / Telegram / X / Facebook / WhatsApp handle given for mission verification |
| **Financial info** → Other financial info | Yes | **Yes** | Optional | App functionality | `Wallet.catcoin_address`, and `Payout` records (address, amount, status, blockchain txid) |
| **Location** → Approximate location | Yes | **Yes** | Required | App functionality, Fraud prevention and security | Country only (ISO alpha-2), derived from the public IP by third-party lookup services, falling back to device locale. **No** GPS, no location permission, never more precise than country |
| **App activity** → App interactions | Yes | No | Required | App functionality, Fraud prevention and security | Mining sessions, mission completions, game scores, leaderboard standings, in-app actions |
| **App info and performance** → Crash logs | Yes | No | Required | App functionality | Diagnostic reports emailed to the operator's inbox on unrecoverable client errors |
| **App info and performance** → Diagnostics | Yes | No | Required | App functionality | App version, platform, OS version, locale, screen, error class, HTTP status, recent-action tail |
| **Device or other IDs** → Device or other IDs | Yes | **Yes** | Required | Advertising or marketing, Fraud prevention and security, App functionality | Google Advertising ID (shared with AdMob); installation UUID sent as `X-Device-ID`; public IP address; Google Play install referrer |

### "Required, or can users choose?" — two Optional, the rest Required

Play offers one answer per data type: *collection is required (users can't turn it off)* or
*users can choose whether this data is collected*. Only two types are optional:

- **Name** — `display_name` is nullable and the signup handler sets it to `None` with
  "User can set this later". Sign-up asks only for **email and password**, so a user can
  use the app without ever providing a name. **Users can choose.**
- **Financial info** — a Catcoin address is supplied only if the user wants to withdraw.
  **Users can choose.**

Everything else is **Required**, because collection happens automatically with no in-app
setting to disable it: the country lookup runs on sign-in, app activity is inherent to
mining and games, and the advertising ID, installation UUID, and IP are attached to
requests regardless. Diagnostics deserve a note — `DiagnosticService` is gated on **no**
user preference and there is no opt-out anywhere in the UI, so crash logs and diagnostics
are Required, not optional.

**User IDs is the one type that needed a judgement call.** It mixes mandatory and optional
items: the account UUID and 9-digit username are generated by the server at signup and
cannot be declined, while the social handles are supplied only for mission verification.
Because part of the type cannot be turned off, the honest single answer is **Required** —
answering "users can choose" would imply the whole type is avoidable, which it is not.

### "Is this data processed ephemerally?" — No, for every type

Play asks this per data type. Answer **No** everywhere. Ephemeral means the data is
accessed **only in memory** and is not retained beyond servicing the request; it is an
exception to declaring collection, so answering Yes incorrectly would under-declare.

Everything above is written to the Postgres `users` table or a related table
(`Wallet`, `Payout`, sessions, scores), which is straightforward persistence. Two types
look like candidates but are not:

- **Crash logs / Diagnostics.** There is no `DiagnosticReport` table and the handler never
  calls `db.add()` / `commit()`, so nothing is persisted to the database — but the report is
  **emailed** to the operator's inbox, where it stays, and `routers/diagnostics.py` also logs
  the platform, app version, HTTP status, user id, and IP to the server log, which is bind
  mounted to `./logs`. Retained in two places, so: **No**.
- **IP address used for rate limiting.** `services/auth_rate_limit.py` keeps only an in-memory
  `defaultdict` of timestamps per IP, which on its own would qualify. But the same IP is
  written to `users.ip_address` at signup and login and appears in server logs, and the
  question is asked about the *data type*, not one use of it. So: **No**.

### Why two types are declared as shared

Both were decided deliberately, in favour of the broader declaration. Under-declaring
sharing is the kind of mismatch Play enforces against, and neither answer costs us
anything, so both are **Shared = Yes**. Keep them that way unless the underlying behaviour
changes.

**Financial info — Shared = Yes.** Once a payout is broadcast, the receiving address,
amount, and transaction become permanently public on the Catcoin blockchain and are
readable by any node or block explorer. Nothing is handed to a named company, so it is not
"sharing" in the everyday sense — but the data does leave us and reach third parties, and
it can never be withdrawn. Declared as shared, and disclosed in the privacy policy under
*Data Sharing* and *Payouts and Blockchain Transactions*.

**Approximate location — Shared = Yes.** We never transmit the derived country anywhere.
But the lookup request travels from the user's device to third-party services (GeoJS,
iplocation.net), which necessarily see the public IP the country is derived from. The
input to the location is shared even though the output is not, so it counts.

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
