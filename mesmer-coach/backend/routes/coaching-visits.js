const express = require('express');
const router = express.Router();
const prisma = require('../prisma/client');

router.post('/', async (req, res) => {
  try {
    const visit = await prisma.coachingVisit.create({
      data: req.body
    });
    res.json({ success: true, visit });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
