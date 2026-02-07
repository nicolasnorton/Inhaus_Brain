
const admin = require('firebase-admin');

// Initialize with default credentials (since we are authenticated in the CLI)
admin.initializeApp({
    projectId: 'inhausbrain'
});

const db = admin.firestore();
const auth = admin.auth();

async function createAdminUser() {
    const email = 'nnorton@inhausbrain.com';
    const password = 'Cafeina88$';
    const displayName = 'Nicolas Norton';

    try {
        let userRecord;
        try {
            userRecord = await auth.getUserByEmail(email);
            console.log('User already exists in Auth:', userRecord.uid);
        } catch (e) {
            userRecord = await auth.createUser({
                email,
                password,
                displayName,
            });
            console.log('Successfully created new user in Auth:', userRecord.uid);
        }

        // Update or create Firestore document
        await db.collection('users').doc(userRecord.uid).set({
            id: userRecord.uid,
            email: email,
            displayName: displayName,
            role: 'superAdmin',
            assignedClientIds: []
        }, { merge: true });

        console.log('Successfully updated Firestore document with superAdmin role.');

        // Also set custom claims if the app uses them
        await auth.setCustomUserClaims(userRecord.uid, { role: 'superAdmin' });
        console.log('Successfully set custom claims.');

    } catch (error) {
        console.error('Error creating admin user:', error);
    }
}

createAdminUser();
