const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const prisma = require('./prisma/client');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// Serve uploaded evidence photos as static files
// e.g. GET /uploads/evidence_123.jpg
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Auth
app.use('/api/auth', require('./routes/auth'));

// Enterprises
app.use('/api/enterprises', require('./routes/enterprises'));

// Coaching Visits (includes QC approve/reject)
app.use('/api/coaching-visits', require('./routes/coaching-visits'));

// Assessments
app.use('/api/assessments', require('./routes/assessments'));

// Training Sessions + Attendance
app.use('/api/trainings', require('./routes/trainings'));

// Photo upload (evidence photos stored on server)
app.use('/api/upload', require('./routes/upload'));

// Graduation + Certificate Lock
app.use('/api/graduation', require('./routes/graduation'));

// Health check
app.get('/', (req, res) => {
  res.json({ message: "✅ MESMER Coach Backend is running!" });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on http://0.0.0.0:${PORT}`);
});
