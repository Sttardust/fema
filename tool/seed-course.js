#!/usr/bin/env node
/**
 * Seed FEMA's Firestore with demo courses + lessons so the app has content.
 *
 * Usage:
 *   cd tool && npm install
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
 *   node seed-course.js                     # seed with no videos (player shows "Video unavailable")
 *   node seed-course.js --video-url "https://firebasestorage.googleapis.com/...mp4?alt=media"
 *
 * The service-account key comes from Firebase console → Project settings →
 * Service accounts → Generate new private key (project: fema-b608b).
 *
 * Idempotent: fixed document IDs + merge writes, safe to re-run.
 * Field names match lib/features/library/domain/library_provider.dart and
 * firestore.rules (status == 'published' makes courses world-readable).
 */

const admin = require('firebase-admin');

const videoUrlFlag = process.argv.indexOf('--video-url');
const VIDEO_URL = videoUrlFlag !== -1 ? process.argv[videoUrlFlag + 1] : null;
if (videoUrlFlag !== -1 && !VIDEO_URL) {
  console.error('--video-url given without a value');
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.applicationDefault() });
const db = admin.firestore();

const COURSES = [
  {
    id: 'seed-physics-motion',
    data: {
      title: 'Physics: Motion & Forces',
      description:
        'Master the fundamentals of motion and forces — from speed and velocity to ' +
        "Newton's laws. Built for the Grade 9 national curriculum with worked examples " +
        'in every lesson.',
      subject: 'science',
      grade: 'Grade 9',
      thumbnailUrl: '',
      rating: 4.8,
      totalStudents: 0,
      ownerId: null,
      status: 'published',
    },
    lessons: [
      {
        id: 'lesson-01',
        title: 'Introduction to Motion',
        description: 'What motion is, frames of reference, and why it matters.',
        durationMinutes: 9,
      },
      {
        id: 'lesson-02',
        title: 'Speed and Velocity',
        description: 'Speed is distance over time; velocity adds direction.',
        durationMinutes: 12,
      },
      {
        id: 'lesson-03',
        title: "Newton's First Law",
        description: 'Inertia and balanced forces, with everyday examples.',
        durationMinutes: 14,
      },
    ],
  },
  {
    id: 'seed-math-algebra',
    data: {
      title: 'Grade 9 Algebra Basics',
      description:
        'Variables, expressions, and linear equations explained step by step. ' +
        'Each lesson ends with practice problems drawn from past national exams.',
      subject: 'math',
      grade: 'Grade 9',
      thumbnailUrl: '',
      rating: 4.7,
      totalStudents: 0,
      ownerId: null,
      status: 'published',
    },
    lessons: [
      {
        id: 'lesson-01',
        title: 'Variables and Expressions',
        description: 'Turning word problems into algebraic expressions.',
        durationMinutes: 10,
      },
      {
        id: 'lesson-02',
        title: 'Solving Linear Equations',
        description: 'One-step and two-step equations, checked by substitution.',
        durationMinutes: 13,
      },
      {
        id: 'lesson-03',
        title: 'Graphing Lines',
        description: 'Slope, intercepts, and reading graphs.',
        durationMinutes: 11,
      },
    ],
  },
];

async function seed() {
  for (const course of COURSES) {
    const courseRef = db.collection('courses').doc(course.id);
    await courseRef.set(
      { ...course.data, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
    for (const lesson of course.lessons) {
      const { id, ...lessonData } = lesson;
      await courseRef.collection('lessons').doc(id).set(
        {
          ...lessonData,
          videoUrl: VIDEO_URL, // null until Storage is enabled and a real URL is passed
          contentHtml: null,
        },
        { merge: true },
      );
    }
    console.log(`Seeded ${course.id} (${course.lessons.length} lessons)`);
  }
  console.log(
    VIDEO_URL
      ? 'Done. Lessons point at the provided video URL.'
      : 'Done. No videoUrl set — lessons will show "Video unavailable" until you re-run with --video-url.',
  );
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Seed failed:', err.message);
    process.exit(1);
  });
