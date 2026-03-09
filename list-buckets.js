const { Storage } = require('@google-cloud/storage');
const storage = new Storage({
    projectId: 'dept-nav-app',
});

async function listBuckets() {
    try {
        const [buckets] = await storage.getBuckets();
        console.log('Buckets:');
        buckets.forEach(bucket => {
            console.log(bucket.name);
        });
    } catch (e) {
        console.error('Failed to list buckets:', e.message);
    }
}

listBuckets();
