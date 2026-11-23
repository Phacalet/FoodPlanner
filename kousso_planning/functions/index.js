/**
 * Cloud Functions – Planning Cuisine
 *  1. electValidator : calcule le valideur à partir des votes (majorité absolue).
 *  2. weeklyReminder : chaque jour à 9h (heure d'Abidjan), push aux familles
 *     dont la semaine en cours n'est pas entièrement remplie.
 *  3. notifyDayChange : prévient les autres membres quand un menu est modifié ou validé.
 */
const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

const JOURS = ['dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi'];
const TZ = 'Africa/Abidjan';

// ---------- 1. Élection du valideur ----------
exports.electValidator = onDocumentWritten('circles/{cid}', async (event) => {
  const after = event.data.after.data();
  if (!after) return;
  const members = after.memberIds || [];
  const votes = after.validatorVotes || {};
  let elected = null;
  if (members.length === 1) {
    elected = members[0];
  } else {
    const count = {};
    for (const [voter, cand] of Object.entries(votes)) {
      if (members.includes(voter) && members.includes(cand)) count[cand] = (count[cand] || 0) + 1;
    }
    for (const [cand, n] of Object.entries(count)) {
      if (n * 2 > members.length) elected = cand;
    }
  }
  if ((after.validatorId || null) !== elected) {
    await event.data.after.ref.update({ validatorId: elected });
  }
});

// ---------- outils ----------
function ymd(d) {
  return d.toISOString().slice(0, 10);
}
function currentWeekKeys(now = new Date()) {
  const day = (now.getUTCDay() + 6) % 7; // lundi = 0
  const monday = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate() - day));
  return Array.from({ length: 7 }, (_, i) => ymd(new Date(monday.getTime() + i * 86400000)));
}
async function tokensOf(uids) {
  if (!uids.length) return [];
  const snaps = await db.getAll(...uids.map((u) => db.collection('users').doc(u)));
  return snaps.flatMap((s) => (s.exists ? s.data().fcmTokens || [] : []));
}
async function push(uids, title, body, data = {}) {
  const tokens = await tokensOf(uids);
  if (!tokens.length) return;
  const res = await admin.messaging().sendEachForMulticast({
    tokens,
    notification: { title, body },
    data,
    android: { notification: { channelId: 'planning_cuisine' } },
  });
  // Nettoyage des jetons expirés
  const dead = tokens.filter((_, i) => !res.responses[i].success);
  if (dead.length) {
    const batch = db.batch();
    for (const u of uids) {
      batch.update(db.collection('users').doc(u), {
        fcmTokens: admin.firestore.FieldValue.arrayRemove(...dead),
      });
    }
    await batch.commit().catch(() => {});
  }
}

// ---------- 2. Rappel pour remplir la semaine ----------
exports.weeklyReminder = onSchedule({ schedule: '0 9 * * *', timeZone: TZ }, async () => {
  const keys = currentWeekKeys();
  const today = ymd(new Date());
  const remainingKeys = keys.filter((k) => k >= today);
  const circles = await db.collection('circles').get();

  for (const c of circles.docs) {
    const days = await c.ref.collection('days')
      .where(admin.firestore.FieldPath.documentId(), 'in', remainingKeys).get();
    const filled = new Set(
      days.docs
        .filter((d) => Object.values(d.data().choices || {}).some((l) => l.length))
        .map((d) => d.id),
    );
    const notLocked = days.docs.filter((d) => !d.data().locked).map((d) => d.id);
    const empty = remainingKeys.filter((k) => !filled.has(k));
    const members = c.data().memberIds || [];

    if (empty.length) {
      const names = empty.map((k) => JOURS[new Date(k + 'T12:00:00Z').getUTCDay()]);
      await push(
        members,
        `🍲 ${empty.length} jour${empty.length > 1 ? 's' : ''} sans menu cette semaine`,
        `Il reste ${names.join(', ')} à remplir. On s'y met ensemble ?`,
        { type: 'reminder' },
      );
    } else if (notLocked.length && c.data().validatorId) {
      await push(
        [c.data().validatorId],
        '🔒 Des menus attendent votre validation',
        `${notLocked.length} fiche(s) de la semaine ne sont pas encore verrouillées.`,
        { type: 'validate' },
      );
    }
  }
});

// ---------- 3. Notification de modification / validation ----------
exports.notifyDayChange = onDocumentWritten('circles/{cid}/days/{dateKey}', async (event) => {
  const before = event.data.before.data() || {};
  const after = event.data.after.data();
  if (!after) return;
  const circleSnap = await db.collection('circles').doc(event.params.cid).get();
  const circle = circleSnap.data();
  if (!circle) return;
  const jour = JOURS[new Date(event.params.dateKey + 'T12:00:00Z').getUTCDay()];
  const names = circle.memberNames || {};

  if (!before.locked && after.locked) {
    const others = circle.memberIds.filter((u) => u !== after.lockedBy);
    return push(others, `✅ Menu de ${jour} validé`, `${names[after.lockedBy] || 'Le valideur'} a verrouillé le menu. Bon appétit !`,
      { type: 'locked', date: event.params.dateKey });
  }

  // Modification : on évite d'envoyer une notif à chaque case cochée (1 max / 15 min).
  const editor = after.lastEditedBy;
  if (!editor || after.locked) return;
  const prevAt = before.updatedAt ? before.updatedAt.toMillis() : 0;
  const nowAt = after.updatedAt ? after.updatedAt.toMillis() : Date.now();
  if (before.lastEditedBy === editor && nowAt - prevAt < 15 * 60 * 1000) return;
  const others = circle.memberIds.filter((u) => u !== editor);
  return push(others, `✏️ ${names[editor] || 'Quelqu\'un'} a modifié le menu de ${jour}`,
    'Jetez un œil et donnez votre accord 👍🏾', { type: 'edit', date: event.params.dateKey });
});
