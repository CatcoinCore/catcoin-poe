# Catcoin PoE - Beta Testing Instructions (v4)

Welcome to the Beta Testing program for Catcoin PoE! This version includes the new **CatCoin Runner** game engine and **Leaderboards**, alongside our core community features.

## 1. Getting Started

### Installation
- **Android (Google Play)**: Use your testing track URL, e.g. `https://play.google.com/store/apps/details?id=YOUR.PACKAGE.NAME`
- **iOS**: (Currently unavailable)

*Note: Please ensure you are on version **1.3.11** or higher. If installing an APK directly, enable "Install from unknown sources".*

---

## 2. Core Features (Legacy)

### 🔐 Authentication & Profile
- [ ] **Sign up**: Create a new account. Check if the email verification code arrives and works.
- [ ] **Login**: Log out and log back in.
- [ ] **Password Reset**: Try the "Forgot Password" flow to ensure you can reset your credentials.
- [ ] **Update Info**: Change your profile picture or update your username in the settings.
- [ ] **App Settings**: Toggle sound/notifications if available.

### ⛏️ Earning Activity & Dashboard
- [ ] **Start Session**: Tap the earn button. Verify the animation plays and the session starts.
- [ ] **Timer**: Check if the countdown timer works correctly.
- [ ] **Ads**: If an ad appears, watch it to see if it rewards you or boosts the session correctly.
- [ ] **Background Mode**: Minimize the app while earning and open it later. Check if the timer continued correctly.

### 💰 Wallet & Payouts
- [ ] **Balance**: Check if your balance updates after an earning session ends.
- [ ] **Payout History**: View your transaction history in the "Wallet" or "History" tab.
- [ ] **Withdrawal (Mock)**: Try to initiate a withdrawal (if enabled) and see if the UI flows correctly.

### 👥 Referrals
- [ ] **Share Link**: Use the "Invite Friend" button to share your referral link.
- [ ] **Referral Code**: If possible, have a friend sign up with your code and check if your referral count increases.

---

## 3. New Features

### 🏃‍♂️ CatCoin Runner
Explore the side-scrolling runner game and verify the following mechanics:
- [ ] **Core Movement**: Tap the screen to jump. Verify responsiveness.
- [ ] **Coin Collection**: Collect 'Catoshi' coins. Ensure the counter in the HUD updates immediately.
- [ ] **Obstacles & Enemies**: Verify that hitting an obstacle or enemy triggers the "Game Over" screen.
- [ ] **Powerups**:
    - **Turbo**: Collect coins to fill the Turbo Meter. Tap the meter when full to activate high-speed invincibility.
    - **Magnet**: Pick up the Magnet powerup and verify it pulls coins toward you.
    - **Shield**: Pick up the Shield and verify it absorbs one hit from an enemy.
- [ ] **Economy**: Check if your "Total Catoshi" in the main wallet updates after a game session ends.

### 🏆 Leaderboard & Awards
Verify how you rank against other miners:
- [ ] **Global Rankings**: Check if you can see the top miners and your own position (highlighted in orange).
- [ ] **Country Flags**: Verify that user flags (or a globe icon) are displayed correctly.
- [ ] **Awards Room**: Tap the trophy icon in the top right of the leaderboard screen to enter the Awards Room.
- [ ] **Pull to Refresh**: Pull down on the leaderboard list to refresh the data.

---

## 4. Missions & Rewards

- [ ] **Daily Rewards**: Claim your daily check-in bonus.
- [ ] **Standard Missions**: Attempt to complete a standard mission (e.g., "Join Telegram"). Verify the status updates to "Completed".
- [ ] **X (Twitter) Missions**:
    - [ ] **Connect Account**: Verify the X account binding process works smoothly.
    - [ ] **Follow/Like/Repost**: Perform the action on X, return, and verify the reward is granted.

---

## 5. How to Report Feedback

Standardized feedback helps us fix issues faster. Please use the template below.

### 📋 Tester Feedback Card
*Copy and paste this into your report:*

```text
--- TESTER FEEDBACK ---
Device: [e.g., Pixel 7 / iPhone 13]
OS Version: [e.g., Android 14]
App Version: 1.3.11

[ ] BUG: I found something broken.
[ ] SUGGESTION: I have an idea to improve the app.
[ ] PERFORMANCE: The app feels laggy/slow.

DESCRIPTION:
[What happened? / What is your idea?]

STEPS TO REPRODUCE (if bug):
1. Open the app...
2. Tap on...
3. Observed result: ...
--- END ---
```

### Reporting Channels:
- **Play Store**: Use the "Contact Developer" or "Testing Feedback" button in the testing section.
- **Email**: `beta-feedback@YOURDOMAIN` *(maintainers: set a real address)*
- **Discord**: Post in the `#beta-feedback` channel.

**Thank you for helping us build the future of Catcoin! 🚀**
