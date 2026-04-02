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

router.get('/', async (req, res) => {
  try {
    const { enterpriseId } = req.query;
    const visits = await prisma.coachingVisit.findMany({
      where: enterpriseId ? { enterpriseId: parseInt(enterpriseId) } : {},
      orderBy: { date: 'desc' },
      include: { enterprise: true }
    });
    res.json(visits);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.get('/coach-performance', async (req, res) => {
  try {
    const visits = await prisma.coachingVisit.findMany({
      include: { enterprise: true }
    });

    const users = await prisma.user.findMany({
      where: { role: 'Coach' }
    });

    const performance = users.map(user => {
      const coachVisits = visits.filter(v => v.createdBy === user.id);
      const enterprises = new Set(coachVisits.map(v => v.enterpriseId));
      const totalVisits = coachVisits.length;
      const avgSessions = enterprises.size > 0 ? (totalVisits / enterprises.size).toFixed(1) : 0;
      const completed = coachVisits.filter(v => v.sessionNo >= 8).length;

      return {
        coachId: user.id,
        coachName: user.name,
        totalVisits: totalVisits,
        enterprisesHandled: enterprises.size,
        avgSessionsPerEnterprise: avgSessions,
        completionRate: enterprises.size > 0 ? Math.round((completed / enterprises.size) * 100) : 0
      };
    });

    res.json(performance);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
