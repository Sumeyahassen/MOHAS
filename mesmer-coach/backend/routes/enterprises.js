const express = require('express');
const router = express.Router();
const prisma = require('../prisma/client');

// Get all enterprises
router.get('/', async (req, res) => {
  const enterprises = await prisma.enterprise.findMany();
  res.json(enterprises);
});

// Create new enterprise
router.post('/', async (req, res) => {
  const enterprise = await prisma.enterprise.create({ data: req.body });
  res.json(enterprise);
});

// Get IAP for one enterprise
router.get('/:id/iap', async (req, res) => {
  try {
    const iap = await prisma.iap.findFirst({
      where: { enterpriseId: parseInt(req.params.id) }
    });
    res.json(iap || { tasks: [] });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create or Update IAP
router.post('/:id/iap', async (req, res) => {
  try {
    const { id } = req.params;
    const { tasks } = req.body;

    if (!tasks || !Array.isArray(tasks)) {
      return res.status(400).json({ error: "tasks must be an array" });
    }

    // Check if IAP already exists
    let iap = await prisma.iap.findFirst({
      where: { enterpriseId: parseInt(id) }
    });

    if (iap) {
      // Update existing
      iap = await prisma.iap.update({
        where: { id: iap.id },
        data: { tasks: tasks }
      });
    } else {
      // Create new
      iap = await prisma.iap.create({
        data: {
          enterpriseId: parseInt(id),
          tasks: tasks,
          signedByCoach: false,
          signedByOwner: false
        }
      });
    }

    res.json({ success: true, message: "IAP saved successfully", iap });
  } catch (error) {
    console.error("IAP Save Error:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
