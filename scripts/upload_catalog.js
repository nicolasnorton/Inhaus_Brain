const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Initialize Firebase Admin (uses Application Default Credentials in Functions environment)
if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

async function uploadCatalog() {
    console.log('🚀 Starting service catalog upload to Firestore...');

    // Load JSON file
    const catalogPath = path.join(__dirname, '..', 'assets', 'data', 'service_catalog.json');

    if (!fs.existsSync(catalogPath)) {
        console.error('❌ Error: service_catalog.json not found at', catalogPath);
        process.exit(1);
    }

    const catalogJson = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));

    console.log(`✅ Loaded catalog JSON with ${catalogJson.services.length} services`);
    console.log(`   - Name: ${catalogJson.name}`);
    console.log(`   - Version: ${catalogJson.version}`);

    // Count service types
    const packages = catalogJson.services.filter(s => s.type === 'bundle').length;
    const individual = catalogJson.services.filter(s => s.type === 'individual').length;

    console.log(`   - Packages: ${packages}`);
    console.log(`   - Individual Services: ${individual}`);

    // Upload to Firestore
    const catalogRef = db
        .collection('knowledge')
        .doc('agency_services')
        .collection('data')
        .doc('catalog');

    console.log('📤 Uploading to Firestore...');
    console.log('   Path: /knowledge/agency_services/data/catalog');

    await catalogRef.set(catalogJson);

    console.log('✅ Successfully uploaded catalog to Firestore!');
    console.log('');
    console.log('🎉 Done! The new INHAUS catalog is now live.');
    console.log('   Refresh your app to see the updated services.');

    process.exit(0);
}

// Export for Firebase Functions or run directly
if (require.main === module) {
    uploadCatalog().catch(error => {
        console.error('❌ Error uploading catalog:', error);
        process.exit(1);
    });
}

module.exports = { uploadCatalog };
