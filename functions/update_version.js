const admin = require('firebase-admin');

try {
    admin.initializeApp({
        credential: admin.credential.applicationDefault(),
        projectId: 'sartarosh-eaf90'
    });

    const db = admin.firestore();

    db.collection('settings').doc('app').set({
        latestVersion: '1.0.8+9',
        isRequired: false
    }, { merge: true })
        .then(() => {
            console.log('Successfully updated latestVersion to 1.0.8+9!');
            process.exit(0);
        })
        .catch(err => {
            console.error('Error updating document: ', err);
            process.exit(1);
        });
} catch (e) {
    console.error("Initialization error: ", e);
    process.exit(1);
}
