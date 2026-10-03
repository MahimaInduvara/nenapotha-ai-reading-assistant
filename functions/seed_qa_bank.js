// functions/seed_qa_bank.js
// Run once to populate the Firestore qaBank collection with starter entries.
// Usage: node seed_qa_bank.js
// Requires: npm install firebase-admin (inside functions/), and either
// GOOGLE_APPLICATION_CREDENTIALS env var pointing at a service account key,
// or run this from an environment already authenticated via `firebase login`.

const admin = require('firebase-admin');
admin.initializeApp();
const db = admin.firestore();

const seedData = [
  {
    questionText: 'what does this word mean',
    keywords: ['word', 'mean', 'meaning', 'means', 'what', 'is'],
    answerEn: "Great question! Tap on any word in the story and I'll show you its meaning with a picture!",
    answerSi: 'හොඳ ප්‍රශ්නයක්! කතාවේ ඕනෑම වචනයක් ස්පර්ශ කර එහි අර්ථය පින්තූරයක් සමඟ බලන්න!',
    category: 'word_meaning',
    gradeLevel: null,
    isActive: true,
    timesMatched: 0,
  },
  {
    questionText: 'how do i start a quiz',
    keywords: ['quiz', 'start', 'test', 'questions'],
    answerEn: 'Tap the "Quiz Me" button and I\'ll ask you questions about the story you just read!',
    answerSi: '"ප්‍රශ්නය" බොත්තම ස්පර්ශ කරන්න, එවිට ඔබ කියවූ කතාව ගැන මම ප්‍රශ්න අහන්නම්!',
    category: 'how_to_use_app',
    gradeLevel: null,
    isActive: true,
    timesMatched: 0,
  },
  {
    questionText: 'i cannot read this',
    keywords: ['cannot', 'read', 'hard', 'difficult', 'understand'],
    answerEn: "That's okay! Try tapping the \"Read Aloud\" button so I can read it to you first.",
    answerSi: 'කමක් නෑ! මුලින්ම "හඬින් කියවන්න" බොත්තම ස්පර්ශ කර මට එය ඔබට කියවා දෙන්න ඉඩ දෙන්න.',
    category: 'encouragement',
    gradeLevel: null,
    isActive: true,
    timesMatched: 0,
  },
  {
    questionText: 'i got it wrong',
    keywords: ['wrong', 'mistake', 'failed', 'lost'],
    answerEn: "That's totally okay! Getting it wrong helps you learn. Want to try again?",
    answerSi: 'කමක් නෑ! වැරදීම ඉගෙනීමට උදව් වෙනවා. ආයෙත් උත්සාහ කරන්නද?',
    category: 'encouragement',
    gradeLevel: null,
    isActive: true,
    timesMatched: 0,
  },
];

async function seed() {
  const batch = db.batch();
  seedData.forEach((entry) => {
    const ref = db.collection('qaBank').doc();
    batch.set(ref, { ...entry, createdAt: admin.firestore.FieldValue.serverTimestamp() });
  });
  await batch.commit();
  console.log(`Seeded ${seedData.length} qaBank entries.`);
}

seed().then(() => process.exit(0)).catch((e) => {
  console.error(e);
  process.exit(1);
});
