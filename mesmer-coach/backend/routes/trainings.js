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
        moduleName,
        date: new Date(date),
        location,
        trainerId: parseInt(trainerId)
      }
    });

    res.json({ success: true, session });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get attendance for a session
router.get('/:id/attendance', async (req, res) => {
  try {
    const sessionId = parseInt(req.params.id);
    // For now, return all enterprises (you can improve later)
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
    const attendanceData = req.body; // { enterpriseId: true/false }

    // For simplicity, we save attendance as JSON in attendance field
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
