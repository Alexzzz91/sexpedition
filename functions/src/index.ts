/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {setGlobalOptions} from "firebase-functions";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {HttpsError, onCall, onRequest} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {createHmac, timingSafeEqual} from "crypto";

// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({ maxInstances: 10 });

admin.initializeApp();

const db = admin.firestore();

function envValue(name: string): string {
  const value = process.env[name]?.trim();
  return value ?? "";
}

type WishDoc = {
  userId?: string;
  type?: string;
  content?: string;
  visibleToPartners?: boolean;
};

function wishTypeLabel(type?: string): string {
  switch (type) {
    case "movie":
      return "Фильм";
    case "thing":
      return "Вещь";
    case "action":
    default:
      return "Действие";
  }
}

export const onWishCreated = onDocumentCreated("wishes/{wishId}", async (event) => {
  const snap = event.data;
  if (!snap) return;
  const wishId = event.params.wishId;
  const wish = snap.data() as WishDoc;
  const fromUserId = wish.userId;
  if (!fromUserId || wish.visibleToPartners != true) return;

  const acceptedFrom = await db
    .collection("connections")
    .where("status", "==", "accepted")
    .where("fromUserId", "==", fromUserId)
    .get();
  const acceptedTo = await db
    .collection("connections")
    .where("status", "==", "accepted")
    .where("toUserId", "==", fromUserId)
    .get();

  const partnerIds = new Set<string>();
  for (const doc of acceptedFrom.docs) {
    const toUserId = doc.data().toUserId;
    if (typeof toUserId === "string" && toUserId !== fromUserId) {
      partnerIds.add(toUserId);
    }
  }
  for (const doc of acceptedTo.docs) {
    const otherUserId = doc.data().fromUserId;
    if (typeof otherUserId === "string" && otherUserId !== fromUserId) {
      partnerIds.add(otherUserId);
    }
  }
  if (partnerIds.size == 0) return;

  const senderDoc = await db.collection("users").doc(fromUserId).get();
  const senderData = senderDoc.data();
  const senderDisplayName = typeof senderData?.displayName == "string" ? senderData.displayName.trim() : "";
  const senderEmail = typeof senderData?.email == "string" ? senderData.email : "";
  const senderName =
    senderDisplayName.length > 0
      ? senderDisplayName
      : (senderEmail.length > 0 ? senderEmail : "Партнер");

  const label = wishTypeLabel(wish.type);
  const normalizedContent = (wish.content ?? "").trim();
  const body = normalizedContent.length > 0
    ? `${senderName} добавил(а) новое желание: ${normalizedContent}`
    : `${senderName} добавил(а) новое желание (${label.toLowerCase()})`;

  for (const toUserId of partnerIds) {
    const notifRef = db.collection("wish_notifications").doc();
    await notifRef.set({
      wishId,
      fromUserId,
      toUserId,
      type: "wish_created",
      wishType: wish.type ?? "action",
      title: "Новое желание партнера",
      body,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isRead: false,
      participants: [fromUserId, toUserId],
    });

    const tokensSnap = await db
      .collection("user_device_tokens")
      .where("userId", "==", toUserId)
      .get();
    const tokens = tokensSnap.docs
      .map((d) => d.data().token)
      .filter((t): t is string => typeof t == "string" && t.length > 0);
    if (tokens.length == 0) continue;

    const response = await admin.messaging().sendEachForMulticast({
      tokens,
      notification: {
        title: "Новое желание партнера",
        body,
      },
      data: {
        type: "wish_created",
        notificationId: notifRef.id,
        wishId,
        fromUserId,
      },
    });

    if (response.failureCount > 0) {
      for (let i = 0; i < response.responses.length; i++) {
        const item = response.responses[i];
        if (item.success) continue;
        const token = tokens[i];
        const code = item.error?.code ?? "";
        if (
          code == "messaging/registration-token-not-registered" ||
          code == "messaging/invalid-registration-token"
        ) {
          const docsWithToken = tokensSnap.docs.filter((d) => d.data().token == token);
          for (const deadTokenDoc of docsWithToken) {
            await deadTokenDoc.ref.delete();
          }
        }
      }
    }
  }
});

type TelegramWebAppUser = {
  id: number;
  username?: string;
  first_name?: string;
  last_name?: string;
};

function verifyTelegramInitData(initData: string, botToken: string): URLSearchParams {
  const params = new URLSearchParams(initData);
  const receivedHash = params.get("hash");
  if (!receivedHash) {
    throw new HttpsError("invalid-argument", "Telegram hash is missing.");
  }

  const entries: Array<[string, string]> = [];
  params.forEach((value, key) => {
    if (key !== "hash") {
      entries.push([key, value]);
    }
  });
  entries.sort((a, b) => a[0].localeCompare(b[0]));
  const dataCheckString = entries.map(([k, v]) => `${k}=${v}`).join("\n");

  const secretKey = createHmac("sha256", "WebAppData").update(botToken).digest();
  const calculatedHash = createHmac("sha256", secretKey)
    .update(dataCheckString)
    .digest("hex");

  const a = Buffer.from(receivedHash, "hex");
  const b = Buffer.from(calculatedHash, "hex");
  if (a.length !== b.length || !timingSafeEqual(a, b)) {
    throw new HttpsError("permission-denied", "Telegram data signature mismatch.");
  }

  const authDateRaw = params.get("auth_date");
  const authDate = authDateRaw ? Number(authDateRaw) : NaN;
  if (!Number.isFinite(authDate)) {
    throw new HttpsError("invalid-argument", "Telegram auth_date is invalid.");
  }
  const authAgeSec = Math.floor(Date.now() / 1000) - authDate;
  if (authAgeSec > 24 * 60 * 60) {
    throw new HttpsError("permission-denied", "Telegram initData is expired.");
  }

  return params;
}

function parseTelegramUser(params: URLSearchParams): TelegramWebAppUser {
  const rawUser = params.get("user");
  if (!rawUser) {
    throw new HttpsError("invalid-argument", "Telegram user payload missing.");
  }
  let user: TelegramWebAppUser;
  try {
    user = JSON.parse(rawUser) as TelegramWebAppUser;
  } catch {
    throw new HttpsError("invalid-argument", "Telegram user payload malformed.");
  }
  if (!Number.isFinite(user.id)) {
    throw new HttpsError("invalid-argument", "Telegram user id is invalid.");
  }
  return user;
}

function telegramDisplayName(user: TelegramWebAppUser): string {
  const first = user.first_name?.trim() ?? "";
  const last = user.last_name?.trim() ?? "";
  const full = `${first} ${last}`.trim();
  if (full.length > 0) return full;
  if ((user.username ?? "").trim().length > 0) return `@${user.username!.trim()}`;
  return `Telegram ${user.id}`;
}

export const telegramWebAppSignIn = onCall(
  async (request) => {
    const initData = request.data?.initData;
    if (typeof initData !== "string" || initData.trim().length === 0) {
      throw new HttpsError("invalid-argument", "initData is required.");
    }

    const botToken = envValue("TELEGRAM_BOT_TOKEN");
    if (!botToken || botToken.trim().length === 0) {
      throw new HttpsError("failed-precondition", "Telegram bot token is not configured.");
    }

    const params = verifyTelegramInitData(initData, botToken);
    const tgUser = parseTelegramUser(params);
    const uid = `tg_${tgUser.id}`;
    const displayName = telegramDisplayName(tgUser);
    const pseudoEmail = `telegram_${tgUser.id}@telegram.local`;

    try {
      await admin.auth().getUser(uid);
      await admin.auth().updateUser(uid, {
        displayName,
      });
    } catch (error: unknown) {
      const code = (error as {code?: string}).code ?? "";
      if (code === "auth/user-not-found") {
        await admin.auth().createUser({
          uid,
          displayName,
        });
      } else {
        throw error;
      }
    }

    await db.collection("users").doc(uid).set({
      displayName,
      email: pseudoEmail,
      telegramUserId: String(tgUser.id),
      telegramUsername: tgUser.username ?? null,
      authProvider: "telegram_webapp",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    }, {merge: true});

    const customToken = await admin.auth().createCustomToken(uid, {
      provider: "telegram_webapp",
      telegramUserId: String(tgUser.id),
    });

    return {
      customToken,
      uid,
      displayName,
      telegramUsername: tgUser.username ?? null,
    };
  },
);

type TelegramUpdate = {
  message?: {
    chat?: {id?: number};
    text?: string;
  };
};

async function sendTelegramBotMessage(
  botToken: string,
  chatId: number,
  text: string,
  webAppUrl: string,
): Promise<void> {
  const endpoint = `https://api.telegram.org/bot${botToken}/sendMessage`;
  await fetch(endpoint, {
    method: "POST",
    headers: {"Content-Type": "application/json"},
    body: JSON.stringify({
      chat_id: chatId,
      text,
      reply_markup: {
        inline_keyboard: [[{
          text: "Открыть Sexpedition",
          web_app: {url: webAppUrl},
        }]],
      },
    }),
  });
}

export const telegramBotWebhook = onRequest(
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).send("Method Not Allowed");
      return;
    }

    const update = (req.body ?? {}) as TelegramUpdate;
    const message = update.message;
    const chatId = message?.chat?.id;
    const text = message?.text?.trim() ?? "";
    if (!chatId) {
      res.status(200).send("ok");
      return;
    }

    if (text.startsWith("/start")) {
      const botToken = envValue("TELEGRAM_BOT_TOKEN");
      const webAppUrl = envValue("TELEGRAM_WEBAPP_URL");
      if (botToken && webAppUrl) {
        await sendTelegramBotMessage(
          botToken,
          chatId,
          "Открой приложение по кнопке ниже:",
          webAppUrl,
        );
      }
    }

    res.status(200).send("ok");
  },
);
