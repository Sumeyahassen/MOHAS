const express = require('express');
const router = express.Router();
const prisma = require('../prisma/client');

// Get all training sessions
router.get('/', async (req, res) => {
  try {
    const sessions = await prisma.trainingSession.findMany({
      orderBy: { date: 'desc' }
    });
    res.json(sessions);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create new training session
router.post('/', async (req, res) => {
  try {
    const { moduleName, date, location, trainerId } = req.body;

    const session = await prisma.trainingSession.create({
      data: {
        moduleName: moduleName || 'Untitled Training',
        date: new Date(date),
        location: location || 'Not specified',
        trainerId: parseInt(trainerId) || 1,
        attendance: {}   // ← This fixes the error
      }
    });

    res.json({ success: true, session });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Get attendance for a session
router.get('/:id/attendance', async (req, res) => {
  try {
    const enterprises = await prisma.enterprise.findMany({
      select: { id: true, enterpriseName: true, ownerName: true }
    });
    res.json(enterprises);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Save attendance
router.post('/:id/attendance', async (req, res) => {
  try {
    const sessionId = parseInt(req.params.id);
    const attendanceData = req.body;

    const session = await prisma.trainingSession.update({
      where: { id: sessionId },
      data: { attendance: attendanceData }
    });

    res.json({ success: true, session });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
