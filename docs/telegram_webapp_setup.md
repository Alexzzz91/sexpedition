# Telegram Web App Setup

## 1) Create bot and set Mini App URL

1. Open BotFather and create a bot (`/newbot`).
2. Create `functions/.env` with:
   - `TELEGRAM_BOT_TOKEN=<your_bot_token>`
   - `TELEGRAM_WEBAPP_URL=https://sexpedition-55.web.app`
3. Deploy functions:
   - `firebase deploy --only functions`

### Local-only alternative (temporary)

For local emulators this same `functions/.env` file will be used automatically.

Important: do not commit this file to git.

## 2) Configure webhook for `/start`

After deploy, set Telegram webhook to `telegramBotWebhook` endpoint:

- `https://<region>-<project>.cloudfunctions.net/telegramBotWebhook`

Use Telegram Bot API:

- `https://api.telegram.org/bot<TELEGRAM_BOT_TOKEN>/setWebhook?url=<FUNCTION_URL>`

When user sends `/start`, bot replies with inline button opening Web App.

## 3) Optional BotFather UX settings

In BotFather:

1. `/setdescription` - short bot description.
2. `/setuserpic` - bot avatar.
3. `/setcommands` - set commands:
   - `start - Открыть приложение`

## 4) Auth flow

Inside Telegram:

- App reads `Telegram.WebApp.initData`.
- Client calls Cloud Function `telegramWebAppSignIn`.
- Function validates Telegram signature and returns Firebase custom token.
- App signs in via `signInWithCustomToken`.

Outside Telegram:

- Existing email/password and Google login stay available.
