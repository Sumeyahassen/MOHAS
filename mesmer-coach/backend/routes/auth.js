const express = require('express');
const router = express.Router();
const prisma = require('../prisma/client');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

const SECRET = process.env.JWT_SECRET || "mesmercoach2026supersecret";

// REGISTER new user (for testing)
router.post('/register', async (req, res) => {
  const { name, email, phone, password, role } = req.body;
  const hashedPassword = await bcrypt.hash(password, 10);

  const user = await prisma.user.create({
    data: { name, email, phone, password: hashedPassword, role }
  });

  res.json({ message: "User created", userId: user.id });
});

// LOGIN
router.post('/login', async (req, res) => {
  const { email, password } = req.body;

  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) return res.status(400).json({ message: "User not found" });

  const isMatch = await bcrypt.compare(password, user.password);
  if (!isMatch) return res.status(400).json({ message: "Wrong password" });

  const token = jwt.sign(
    { id: user.id, role: user.role, name: user.name },
    SECRET,
    { expiresIn: '7d' }
  );

  res.json({ 
    success: true, 
    token,
    user: { id: user.id, name: user.name, role: user.role }
  });
});

module.exports = router;

router.get('/coaches', async (req, res) => {
  try {
    const coaches = await prisma.user.findMany({
      where: { role: 'Coach' },
      select: { id: true, name: true }
    });
    res.json(coaches);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
