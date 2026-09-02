# Telegram Bot Setup Guide

This guide explains how to create a Telegram Bot and configure it to verify member joins in your Community Channel or Group.

## 1. Create a Bot
1.  Open Telegram and search for **@BotFather**.
2.  Start a chat and send the command `/newbot`.
3.  Follow the prompts to choose a **Name** (e.g., `Catcoin Verifier`) and a **Username** (e.g., `catcoin_verify_bot`).
4.  **BotFather** will give you an **API Token**.
    - Coppy this token. It looks like: `123456789:ABCdefGHIjllm...`

## 2. Add Bot to Channel/Group
For the bot to verify members, it **MUST** be an Administrator in your Channel or Group.

1.  Open your Community Channel or Group.
2.  Go to **Manage Channel/Group** > **Administrators**.
3.  Click **Add Administrator**.
4.  Search for your bot's username and add it.
5.  Ensure it has permission to **Invite Users** or see members (default admin rights are usually enough).

## 3. Get the Chat ID
You need to tell the backend *which* channel to check.

- **Option A: Public Username**
  If your channel/group is public (e.g., `t.me/yourchannel`), you can simply use the username with the `@` symbol.
  - Value: `@your_channel_username`

- **Option B: Private ID**
  If it's private, you need the numeric ID (usually starts with `-100`).
  1.  Add `@RawDataBot` to your group (remove it after).
  2.  It will print a JSON with the Chat ID.
  3.  Copy the `id` from the `chat` object.

## 4. Configure Your Environment
1.  Open `cat_poe_backend/.env` (create from `cat_poe_backend/.env.example` if needed).
2.  Add or update the following lines:
    ```env
    TELEGRAM_BOT_TOKEN=your_api_token_here
    TELEGRAM_CHAT_ID=@your_channel_username 
    ```
    *(Use the numeric ID if private, or `@username` if public)*

## 5. Verify Configuration
Run the provided script to test the connection:
```bash
python verify_telegram_config.py
```
