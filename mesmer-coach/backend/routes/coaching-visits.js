const express = require('express');
const router = express.Router();
const prisma = require('../prisma/client');

router.post('/', async (req, res) => {
  try {
    const {
      enterpriseId,
      sessionNo,
      keyFocusArea,
      keyIssuesIdentified,
      actionsAgreed,
      evidenceUrls,
      followUpDate,
      followUpType,
      measurableResults
    } = req.body;

    const visit = await prisma.coachingVisit.create({
      data: {
        enterpriseId: parseInt(enterpriseId),
        sessionNo: parseInt(sessionNo),
        date: new Date(),                    // ← Automatically set to today
        keyFocusArea,
        keyIssuesIdentified,
        actionsAgreed,
        evidenceUrls: evidenceUrls || [],
        followUpDate: followUpDate ? new Date(followUpDate) : null,
        followUpType,
        measurableResults: measurableResults || {},
        createdBy: 1                         // Temporary — later we will use JWT user ID
      }
    });

    res.json({ success: true, visit });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
