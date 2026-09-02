# Discord Bot Setup Guide

> **Open source:** This file may contain project-specific IDs and invite URLs. For a public repo, redact or replace them (or keep this doc private). Do not commit real `.env` contents.

This guide helps you set up your Discord Bot for member verification.

## 1. Invite the Bot
Use the following link to invite the bot to your server. This link grants "Administrator" permissions to ensure it can read member lists and manage roles if needed later.

**Invite URL:** `https://discord.com/api/oauth2/authorize?client_id=YOUR_DISCORD_APPLICATION_CLIENT_ID&permissions=8&scope=bot` (replace `YOUR_DISCORD_APPLICATION_CLIENT_ID` with your app’s ID from the Developer Portal).

## 2. Enable Privileged Intents (CRITICAL)
For the bot to verify if a user has joined the server, it needs the **"Server Members Intent"**. Without this, the bot cannot see the member list or search for users.

1. Go to the **[Discord Developer Portal](https://discord.com/developers/applications)**.
2. Click on your application (the Client ID must match the one in your invite URL).
3. On the left sidebar, click **Bot**.
4. Scroll down to the **Privileged Gateway Intents** section.
5. Toggle **ON** the switch for `SERVER MEMBERS INTENT`.
   > *Icon*: ![Server Members Intent Toggle](https://i.imgur.com/K7wXJkL.png) *(generic reference image)*
6. Click **Save Changes** at the bottom.

## 3. Configure Server ID
Set **`DISCORD_GUILD_ID`** in `cat_poe_backend/.env` (never commit `.env`) to your Discord server’s numeric ID.

**Ensure this ID matches the server you invited the bot to.**  
To obtain your Server ID:
1. Enable **Developer Mode** in Discord (User Settings > Advanced > Developer Mode).
2. Right-click your server icon in the sidebar and click **Copy Server ID**.
3. Put that value in `DISCORD_GUILD_ID` in `.env`.

## 4. Verification Check
Run the provided verification script to confirm everything is working:
```bash
python verify_discord_config.py
```
