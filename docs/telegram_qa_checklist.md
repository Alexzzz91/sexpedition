# Telegram Web App QA Checklist

## Smoke (Telegram Mini App)

1. Open bot chat and run `/start`.
2. Tap `Открыть Sexpedition`.
3. Verify app opens inside Telegram webview.
4. Verify auth screen shows Telegram quick login.
5. Tap `Войти через Telegram` and confirm app enters authenticated area.
6. Force close Mini App and open again from bot.
7. Verify session is restored (user remains signed in).

## Regression (Regular browser)

1. Open hosted app URL directly in browser.
2. Verify auth screen shows fallback methods.
3. Verify email/password login still works.
4. Verify Google login button still works (web popup flow).

## Data/Backend checks

1. In Firebase Auth, verify `uid` format `tg_<telegram_id>` appears after Telegram login.
2. In Firestore `users`, verify profile document is upserted for that uid.
3. In Functions logs, verify `telegramWebAppSignIn` has no signature errors for valid launches.

## Bot/Webhook checks

1. Verify webhook is set to `telegramBotWebhook`.
2. Verify `/start` always returns inline keyboard with `web_app` URL.
3. Verify button URL points to production hosting URL.
