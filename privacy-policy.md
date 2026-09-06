# Privacy Policy for Catcoin PoE

**Last Updated:** September 6, 2026

## Introduction

This Privacy Policy describes how Catcoin PoE ("we", "our", or "us") collects, uses, and shares information when you use our mobile application.

## Information We Collect

### Information You Provide
- **Account Information:** Email address, username, and display name when you register
- **Social Media Handles:** Discord, Telegram, X (Twitter), Facebook, and WhatsApp usernames (if you choose to provide them for mission verification)
- **Referral Information:** Referral codes used during signup
- **Catcoin Wallet Address:** The Catcoin (CAT) blockchain address you give us to receive payouts. Providing one is optional, but withdrawals are not possible without it. See [Payouts and Blockchain Transactions](#payouts-and-blockchain-transactions) below for an important note about what becomes public.

### Information Collected Automatically
- **Usage Data:** Mining session activity, mission completions, and in-app actions
- **Device Information:** Device type, operating system version, app version, and an installation identifier — a random UUID the app generates the first time it runs and sends with each request to our servers. We use it to detect duplicate or fraudulent accounts. It is not your hardware serial number, and reinstalling the app produces a new one.
- **Advertising Data:** Google Advertising ID (AAID) on Android devices
- **Install Referrer (Google Play, Android only):** When you open the sign-up screen, the app reads the Google Play install referrer so that a referral code carried by an invite link can be filled in for you. We use it only to pre-fill that referral code.
- **Approximate Location (Country Only):** The app determines the country you are in so it can show country leaderboards, regional awards, and a country flag beside your name. **It does not use your device's GPS or location services and never asks for location permission.** Instead, when you sign in, the app asks one or more third-party lookup services which country your public IP address belongs to (see [Data Sharing](#data-sharing)). If none of them respond, it falls back to the country setting of your device's locale. We store only a two-letter ISO country code (for example `US`) and whether it came from your IP address or from your device locale. We never store coordinates, a street address, or any position more precise than the country.
- **IP Address:** Your public IP address is recorded when you register and when you sign in, and appears in server logs and in the diagnostic reports described below. We use it to derive the country code above, to detect duplicate or fraudulent accounts, and to rate-limit abusive traffic.
- **Diagnostic Reports:** When the app encounters an unrecoverable client-side error (for example, failing to reach the server at boot), it sends a short technical report so the operators can investigate. The report contains the app version, platform, OS version, device locale, the screen where the error occurred, the error class and a sanitised message, the HTTP status code if applicable, your account user ID (a UUID — no email, name, or password is included), and a short tail of recent in-app actions. Reports go to the operator's support inbox configured for the deployment.
- **Age Verification Signal (Google Play, Android only):** When required by law (currently rolling out for new users in Texas via Google Play's Age Signals API), the app reads a status flag from Google indicating whether you have completed age verification. We store only the enumerated status (for example `verified`, `not_verified`, `not_required`) and a timestamp; we do not receive your date of birth, name, or any identity document from Google. The status is used to decide whether to allow account creation, rewards, or withdrawals.

## How We Use Your Information

We use the information we collect to:
- Provide and maintain the app functionality
- Process mining rewards and mission completions
- Verify social media mission requirements
- Enable the referral system
- Send important account notifications via email
- Show global and country leaderboards, monthly regional podium awards, and country flags beside player names
- Send payouts to the Catcoin address you provide, and keep a record of those payouts
- Detect and prevent fraud, duplicate accounts, and abuse, including rate-limiting requests by IP address
- **Display Advertisements:** To show you relevant ads that support our service

## Advertising

We use Google AdMob to display advertisements in our app. Google AdMob may collect and use:
- **Advertising ID:** To provide personalized ads based on your interests
- **Cookies and Usage Data:** To measure the effectiveness of ads and prevent fraud

For more information about how Google AdMob uses your data, please review Google's Privacy Policy:
- [Google Privacy Policy](https://policies.google.com/privacy)
- [How Google uses data when you use our partners' sites or apps](https://policies.google.com/technologies/partner-sites)

You can opt-out of personalized advertising by visiting your device settings (Settings > Google > Ads > Opt out of Ads Personalization).

## Data Sharing

We do not sell your personal information. We may share information:
- **With Ad Partners:** We share device identifiers and usage data with Google AdMob to facilitate advertising services
- **With IP Geolocation Providers:** To determine your country, the app sends a lookup request from your device to one or more of the third-party services listed below. Because the request originates on your device, these services can see your public IP address. They receive no other information about you — no account ID, email, username, or device identifier — and we do not send them your account data. Each publishes its own privacy policy:
  - [GeoJS](https://www.geojs.io/) (`get.geojs.io`)
  - [ip-api.com](https://ip-api.com/docs/legal)
  - [iplocation.net](https://www.iplocation.net/privacy-policy)
- **With Service Providers:** Who help operate our services (e.g., email delivery)
- **Legal Requirements:** If required by law or to protect our rights

## Payouts and Blockchain Transactions

When you request a withdrawal we record the Catcoin address you supplied, the amount, the status of the payout, and — once the payment is broadcast — its blockchain transaction ID.

**The Catcoin blockchain is public and permanent.** After a payout is sent, the receiving address, the amount, and the transaction are visible to anyone, forever. We cannot edit, hide, or reverse them, and deleting your account does not remove them. If your Catcoin address is known to someone else, they may be able to link these payouts to you. This is how public blockchains work rather than a choice we make about your data, but you should understand it before providing an address.

## Data Security

We implement appropriate security measures to protect your information, including encrypted data transmission and secure password storage.

## Data Retention & Account Deletion

We retain your account information as long as your account is active. You may request account deletion at any time from the account deletion page in the app, or by contacting us.

When you delete your account we anonymise your personal information, including your email address, username, and any social handles you supplied. To stop deleted accounts being recreated to farm rewards ("farming"), we keep a cryptographic hash of your identity, which lets us recognise a repeat signup without retaining the underlying details.

Records already written to the Catcoin blockchain cannot be deleted — see [Payouts and Blockchain Transactions](#payouts-and-blockchain-transactions).

## Children's Privacy

Catcoin PoE is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13.

## Your Rights

You have the right to:
- Access your personal information
- Update or correct your information
- Request deletion of your account
- Opt-out of non-essential communications
- Opt-out of personalized ads via device settings

## Changes to This Policy

We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new policy in the app.

## Contact Us

If you have questions about this Privacy Policy, please:

- **Privacy questions** — open a public issue in this repository, or use the contact channel listed in the official app store listing.
- **Security or data-handling concerns** — report privately via [SECURITY.md](SECURITY.md).

Maintainers operating a published app must replace this section with a working contact address that satisfies their app store's privacy-policy requirements before publication.

---

*This privacy policy is effective as of September 6, 2026.*
