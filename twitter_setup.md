# X (Twitter) API Setup Guide

This guide explains how to get the **Bearer Token** required for verifyng if a user follows your community account.

## 1. Create a Developer Account
1.  Go to the [X Developer Portal](https://developer.x.com/en/portal/dashboard).
2.  Sign up for a **Free** account if you haven't already.

## 2. Create a Project & App
1.  In the Dashboard, create a new **Project**.
2.  Give it a name (e.g., "Catcoin Verifier").
3.  Select "Building tools for bots" or a similar use case.
4.  Create a new **App** within this project.

## 3. Generate Bearer Token
Once your App is created, you will see a "Keys and Tokens" section.

1.  Find the **Bearer Token** section.
2.  Click **Regenerate** (or Generate) to create a new token.
3.  **COPY THIS TOKEN IMMEDIATELY.** You will not be able to see it again.

## 4. Configure Your Environment
1.  Open `cat_poe_backend/.env` (create from `cat_poe_backend/.env.example` if needed).
2.  Add or update the following line:
    ```env
    X_BEARER_TOKEN=your_long_bearer_token_here
    X_COMMUNITY_USERNAME=your_community_username
    ```
    *(Use the X handle users must follow for mission verification.)*

## 5. Verify Configuration
Run the provided script to test the connection:
```bash
python verify_twitter_config.py
```

> [!NOTE]
> The Free Tier limits you to **15 requests per 15 minutes** for the "Following" check. The bot handles this by retrying, but heavy usage may hit limits.
