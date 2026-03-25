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
import * as admin from "firebase-admin";

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
