const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const prisma = require('./prisma/client');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// Auth routes
app.use('/api/auth', require('./routes/auth'));

// Enterprises
app.use('/api/enterprises', require('./routes/enterprises'));

// Coaching Visits
app.use('/api/coaching-visits', require('./routes/coaching-visits'));

// Assessments
app.use('/api/assessments', require('./routes/assessments'));

// Training Sessions + Attendance
app.use('/api/trainings', require('./routes/trainings'));

// Test route
app.get('/', (req, res) => {
  res.json({ message: "✅ MESMER Coach Backend is running!" });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 Server running on http://0.0.0.0:${PORT}`);
});
