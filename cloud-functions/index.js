const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * onReminderUpdate - Triggers when any reminder is created, updated, or deleted.
 * Sends FCM silent push to all OTHER devices of the user to sync notification state.
 */
exports.onReminderUpdate = onDocumentWritten(
  "users/{userId}/reminders/{reminderId}",
  async (event) => {
    const userId = event.params.userId;
    const reminderId = event.params.reminderId;

    const beforeData = event.data?.before?.data();
    const afterData = event.data?.after?.data();

    // Determine the action
    let action;
    let payload = { reminderId };

    if (!beforeData && afterData) {
      action = "created";
      payload.title = afterData.title;
      payload.triggerDate = afterData.triggerDate?.toDate()?.toISOString();
    } else if (beforeData && !afterData) {
      action = "deleted";
    } else if (beforeData && afterData) {
      if (beforeData.status === "active" && afterData.status === "completed") {
        action = "completed";
      } else if (
        beforeData.triggerDate?.toMillis() !== afterData.triggerDate?.toMillis() ||
        beforeData.snoozedUntil?.toMillis() !== afterData.snoozedUntil?.toMillis()
      ) {
        action = "snoozed";
        payload.title = afterData.title;
        const newDate = afterData.snoozedUntil || afterData.triggerDate;
        payload.newTriggerDate = newDate?.toDate()?.toISOString();
      } else {
        action = "updated";
        payload.title = afterData.title;
        payload.triggerDate = afterData.triggerDate?.toDate()?.toISOString();
      }
    } else {
      return;
    }

    payload.action = action;

    // Get all devices for this user
    const devicesSnapshot = await db
      .collection("users")
      .doc(userId)
      .collection("devices")
      .get();

    if (devicesSnapshot.empty) return;

    // Collect FCM tokens (exclude empty tokens)
    const tokens = [];
    devicesSnapshot.forEach((doc) => {
      const token = doc.data().fcmToken;
      if (token && token.length > 0) {
        tokens.push(token);
      }
    });

    if (tokens.length === 0) return;

    // Send silent push to all devices
    const message = {
      data: payload,
      apns: {
        payload: {
          aps: {
            "content-available": 1,
          },
        },
      },
      android: {
        priority: "high",
      },
    };

    // Send to each token
    const sendPromises = tokens.map(async (token) => {
      try {
        await messaging.send({ ...message, token });
      } catch (error) {
        // If token is invalid, remove it
        if (
          error.code === "messaging/invalid-registration-token" ||
          error.code === "messaging/registration-token-not-registered"
        ) {
          const tokenDocs = devicesSnapshot.docs.filter(
            (doc) => doc.data().fcmToken === token
          );
          for (const doc of tokenDocs) {
            await doc.ref.delete();
          }
        }
      }
    });

    await Promise.all(sendPromises);
  }
);

/**
 * onDeviceCleanup - Runs daily to remove stale device tokens.
 * Devices not active in 30 days are removed.
 */
exports.onDeviceCleanup = onSchedule("every 24 hours", async () => {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const usersSnapshot = await db.collection("users").get();

  for (const userDoc of usersSnapshot.docs) {
    const devicesSnapshot = await userDoc.ref
      .collection("devices")
      .where("lastActiveAt", "<", thirtyDaysAgo)
      .get();

    const deletePromises = devicesSnapshot.docs.map((doc) => doc.ref.delete());
    await Promise.all(deletePromises);
  }
});
