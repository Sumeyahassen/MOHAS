const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const prisma = require('./prisma/client');

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// Auth route
app.use('/api/auth', require('./routes/auth'));

// Protected routes
app.use('/api/enterprises', require('./routes/enterprises'));
app.use('/api/coaching-visits', require('./routes/coaching-visits'));

// Test route
app.get('/', (req, res) => {
  res.json({ message: "✅ MESMER Coach Backend is RUNNING and ready for phone!" });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, '0.0.0.0', () => {     // ←←← THIS LINE IS THE FIX
  console.log(`🚀 Server running on http://0.0.0.0:${PORT}`);
  console.log(`📱 Use this IP in Flutter: http://192.168.43.231:${PORT}`);
});
