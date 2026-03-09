const { Storage } = require('@google-cloud/storage');

const storage = new Storage({
    projectId: 'dept-nav-app',
});

async function configureBucketCors() {
    try {
        const bucket = storage.bucket('dept-nav-app.appspot.com');

        await bucket.setCorsConfiguration([
            {
                origin: ['*'],
                responseHeader: ['Content-Type', 'x-goog-resumable', 'Authorization'],
                method: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
                maxAgeSeconds: 3600
            }
        ]);

        console.log("Bucket CORS Configuration update successful.");
    } catch (e) {
        console.log("Bucket CORS update failed: ", e.message);
    }
}

configureBucketCors();
