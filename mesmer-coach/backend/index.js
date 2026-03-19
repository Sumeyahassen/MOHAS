const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const prisma = require('./prisma/client');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// Test route
app.get('/', (req, res) => {
  res.json({ 
    message:"MESMER Coach Backend is RUNNING with Prisma!",
    status: "Connected to PostgreSQL",
    database: "mesmer_coach"
  });
});

// === ROUTES WILL BE ADDED HERE ===
app.use('/api/enterprises', require('./routes/enterprises'));
app.use('/api/coaching-visits', require('./routes/coaching-visits'));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 MESMER Coach Backend running on http://localhost:${PORT}`);
});
