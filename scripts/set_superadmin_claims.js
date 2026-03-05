const admin = require('firebase-admin');

admin.initializeApp({ projectId: 'inhausbrain' });
const auth = admin.auth();
const db = admin.firestore();

const SUPERADMIN_EMAILS = [
    'nnorton@inhauscorp.com',
    'nnorton@inhausbrain.com',
];

async function main() {
    for (const email of SUPERADMIN_EMAILS) {
        try {
            const user = await auth.getUserByEmail(email);
            console.log(`Found user ${email} → uid: ${user.uid}`);

            // Set Firebase custom claims
            await auth.setCustomUserClaims(user.uid, {
                role: 'superAdmin',
                superadmin: true,
            });
            console.log(`  ✅ Custom claims set (superadmin: true)`);

            // Ensure Firestore profile also has superAdmin role
            await db.collection('users').doc(user.uid).set({
                role: 'superAdmin',
            }, { merge: true });
            console.log(`  ✅ Firestore profile updated`);

        } catch (e) {
            console.error(`  ❌ Error for ${email}: ${e.message}`);
        }
    }
    console.log('\nDone.');
    process.exit(0);
}

main();
