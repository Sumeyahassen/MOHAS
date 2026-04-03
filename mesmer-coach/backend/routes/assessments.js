const express = require('express');
const router = express.Router();
const prisma = require('../prisma/client');

// Create Assessment (Baseline / Midline / Endline)
router.post('/', async (req, res) => {
  try {
    const { enterpriseId, type, responses } = req.body;

    // Get the logged-in user ID from token (we will use middleware later)
    // For now, we use a temporary value. Later we will use real user ID
    const createdBy = 1;   // TODO: replace with req.user.id from auth middleware

    const assessment = await prisma.assessment.create({
      data: {
        enterpriseId: parseInt(enterpriseId),
        type: type,
        responses: responses,
        createdBy: createdBy
      }
    });

    res.json({ success: true, assessment });
  } catch (error) {
    console.error(error);
    res.status(500).json({ success: false, error: error.message });
  }
});

module.exports = router;
