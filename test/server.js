
const express = require('express');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const bodyParser = require('body-parser');
const { v4: uuidv4 } = require('uuid');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(bodyParser.json({ limit: '10mb' }));
app.use(bodyParser.urlencoded({ extended: true }));

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret_change_me';
const TOKEN_EXPIRES_IN = '1h'; // sample expiry

// --- In-memory mock data stores ---
const users = {
    user_123: { id: 'user_123', email: 'doctor@example.com', name: 'Dr. Tester' }
};

const patients = {
    patient_123: { id: 'patient_123', name: 'John Doe', user_id: 'user_123', pronouns: 'he/him', email: 'john@example.com' }
};

const sessions = {
    // sessionId: {...}
};

const uploadedChunks = [];

const templates = [
    { id: 'template_123', title: 'New Patient Visit', type: 'default' },
    { id: 'template_456', title: 'Follow-up Visit', type: 'predefined' }
];

// --- Auth helpers ---
function signToken(payload, expiresIn = TOKEN_EXPIRES_IN) {
    return jwt.sign(payload, JWT_SECRET, { expiresIn });
}

function verifyToken(token) {
    try {
        return jwt.verify(token, JWT_SECRET);
    } catch (e) {
        return null;
    }
}

// Middleware to protect endpoints
function requireAuth(req, res, next) {
    const auth = req.headers['authorization'];
    if (!auth) return res.status(401).json({ error: 'Missing Authorization header' });
    const parts = auth.split(' ');
    if (parts.length !== 2 || parts[0] !== 'Bearer') return res.status(401).json({ error: 'Malformed Authorization header' });
    const token = parts[1];
    const payload = verifyToken(token);
    if (!payload) return res.status(401).json({ error: 'Invalid or expired token' });
    req.user = payload;
    next();
}

// --- Test login route (for Postman) ---
app.post('/auth/mock-login', (req, res) => {
    // Accept { email } and return a JWT for local testing
    const { email } = req.body;
    // lookup or create mock user
    const userEntry = Object.values(users).find(u => u.email === email) || users['user_123'];
    const token = signToken({ userId: userEntry.id, email: userEntry.email });
    res.json({ token, expiresIn: TOKEN_EXPIRES_IN });
});

// --- Patient Management ---
app.get('/v1/patients', requireAuth, (req, res) => {
    const userId = req.query.userId || req.user.userId;
    const list = Object.values(patients).filter(p => p.user_id === userId);
    res.json({ patients: list });
});

app.post('/v1/add-patient-ext', requireAuth, (req, res) => {
    const { name, userId } = req.body;
    if (!name || !userId) return res.status(400).json({ error: 'Missing name or userId' });
    const id = 'patient_' + uuidv4().slice(0, 8);
    const patient = { id, name, user_id: userId, pronouns: null };
    patients[id] = patient;
    res.status(201).json({ patient });
});

app.get('/v1/patient-details/:patientId', requireAuth, (req, res) => {
    const { patientId } = req.params;
    const p = patients[patientId];
    if (!p) return res.status(404).json({ error: 'Patient not found' });
    // enrich with mock details
    res.json({
        id: p.id,
        name: p.name,
        pronouns: p.pronouns,
        email: p.email || null,
        background: p.background || 'Patient background information',
        medical_history: p.medical_history || 'Previous medical conditions',
        family_history: p.family_history || 'Family medical history',
        social_history: p.social_history || 'Social history information',
        previous_treatment: p.previous_treatment || 'Previous treatments'
    });
});

// --- Session / Recording Management ---
app.post('/v1/upload-session', requireAuth, (req, res) => {
    const { patientId, userId, patientName, status, startTime, templateId } = req.body;
    const id = 'session_' + uuidv4().slice(0, 8);
    const session = {
        id,
        user_id: userId || req.user.userId,
        patient_id: patientId || null,
        patient_name: patientName || null,
        status: status || 'recording',
        start_time: startTime || new Date().toISOString(),
        template_id: templateId || null,
        chunks: [],
        transcript_status: null,
        transcript: null
    };
    sessions[id] = session;
    res.status(201).json({ id });
});

// Return a mock presigned URL. In production, replace the implementation
// to call Google Cloud Storage signed URL APIs (or AWS S3 presigned URL APIs)


app.post('/v1/get-presigned-url', requireAuth, (req, res) => {
    const { sessionId, chunkNumber, mimeType } = req.body;

    if (!sessionId || !Number.isInteger(chunkNumber)) {
        return res.status(400).json({
            error: 'sessionId and valid chunkNumber required',
            received: req.body
        });
    }

    const gcsPath = `sessions/${sessionId}/chunk_${chunkNumber}.wav`;
    // console.log("GCS PATH:", gcsPath);

    // const url = `https://mock-storage.local/upload/${encodeURIComponent(gcsPath)}?mockSigned=1&expires=${Date.now() + 3600_000}`;
    const url = `http://172.25.88.24:3000/upload/${encodeURIComponent(gcsPath)}?mockSigned=1&expires=${Date.now() + 3600_000}`;
    const publicUrl = `https://storage.googleapis.com/mock-bucket/${gcsPath}`;

    res.json({ url, gcsPath, publicUrl });
});

app.use('/upload', express.raw({ type: '*/*', limit: '50mb' }));

// // Optional helper route: support direct PUT for local testing
app.put('/upload/:encodedPath', (req, res) => {
    const encodedPath = req.params.encodedPath;

    // Raw body is available in req.body as Buffer
    const bytes = req.body;

    console.log("Uploaded to:", encodedPath);
    console.log("Bytes received:", bytes.length);

    // Optional: write to disk to simulate GCS
    // const fs = require('fs');
    // fs.mkdirSync('uploads', { recursive: true });
    // fs.writeFileSync(`uploads/${encodedPath}`, bytes);

    res.status(200).send('OK');
});

// Notify backend that chunk was uploaded
app.post('/v1/notify-chunk-uploaded', requireAuth, (req, res) => {
    const body = req.body;
    console.log(req.body);
    const { sessionId, gcsPath, chunkNumber, isLast, totalChunksClient, publicUrl, mimeType, selectedTemplate, selectedTemplateId, model } = body;
    if (!sessionId || !gcsPath)
         return res.status(400).json({ error: 'sessionId and gcsPath required' });

    // record chunk metadata
    uploadedChunks.push({ id: uuidv4(), sessionId, gcsPath, chunkNumber, isLast: !!isLast, totalChunksClient, publicUrl, mimeType, selectedTemplate, selectedTemplateId, model, createdAt: new Date().toISOString() });

    // attach to session object
    if (sessions[sessionId]) sessions[sessionId].chunks.push({ gcsPath, chunkNumber, publicUrl, mimeType, createdAt: new Date().toISOString() });

    // If last chunk, mark session status to 'uploaded' (mock) and queue transcription (mock)
    if (isLast && sessions[sessionId]) {
        sessions[sessionId].status = 'uploaded';
        sessions[sessionId].transcript_status = 'queued';
        // In real deployment you would enqueue a job to process the file(s) and call transcription service
    }

    res.json({});
});

app.get('/v1/fetch-session-by-patient/:patientId', requireAuth, (req, res) => {
    const patientId = req.params.patientId;
    const list = Object.values(sessions).filter(s => s.patient_id === patientId);
    res.json({ sessions: list });
});

app.get('/v1/all-session', requireAuth, (req, res) => {
    const userId = req.query.userId || req.user.userId;
    const list = Object.values(sessions).filter(s => s.user_id === userId).map(s => ({
        id: s.id,
        user_id: s.user_id,
        patient_id: s.patient_id,
        session_title: s.template_id || 'Session',
        session_summary: s.transcript ? s.transcript.slice(0, 200) : null,
        transcript_status: s.transcript_status,
        transcript: s.transcript,
        status: s.status,
        date: s.start_time ? s.start_time.split('T')[0] : null,
        start_time: s.start_time,
        end_time: s.end_time || null,
        patient_name: s.patient_name,
        pronouns: (patients[s.patient_id] && patients[s.patient_id].pronouns) || null,
        email: (patients[s.patient_id] && patients[s.patient_id].email) || null,
        background: (patients[s.patient_id] && patients[s.patient_id].background) || null,
        duration: s.duration || null,
        medical_history: (patients[s.patient_id] && patients[s.patient_id].medical_history) || null,
        family_history: (patients[s.patient_id] && patients[s.patient_id].family_history) || null,
        social_history: (patients[s.patient_id] && patients[s.patient_id].social_history) || null,
        previous_treatment: (patients[s.patient_id] && patients[s.patient_id].previous_treatment) || null,
        patient_pronouns: (patients[s.patient_id] && patients[s.patient_id].pronouns) || null,
        clinical_notes: s.clinical_notes || []
    }));

    const patientMap = Object.fromEntries(Object.values(patients).map(p => [p.id, { name: p.name, pronouns: p.pronouns }]));
    res.json({ sessions: list, patientMap });
});

app.get('/v1/fetch-default-template-ext', requireAuth, (req, res) => {
    const userId = req.query.userId;
    // Return templates - in real system templates might be user-specific
    res.json({ success: true, data: templates });
});

// --- Fallback / healthcheck ---
app.get('/', (req, res) => res.send('MediNote mock backend running'));

// Start server
app.listen(PORT, () => {
    console.log(`MediNote mock backend listening on port ${PORT}`);
    console.log(`Use POST /auth/mock-login {"email":"doctor@example.com"} to get a token`);
});