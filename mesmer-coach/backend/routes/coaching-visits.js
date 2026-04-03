const express = require('express');
const router = express.Router();
const prisma = require('../prisma/client');

// POST /api/coaching-visits — create a new visit
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
      measurableResults,
      createdBy
    } = req.body;

    const visit = await prisma.coachingVisit.create({
      data: {
        enterpriseId: parseInt(enterpriseId),
        sessionNo: parseInt(sessionNo),
        date: new Date(),
        keyFocusArea,
        keyIssuesIdentified,
        actionsAgreed,
        evidenceUrls: evidenceUrls || [],
        followUpDate: followUpDate ? new Date(followUpDate) : null,
        followUpType,
        measurableResults: measurableResults || {},
        createdBy: parseInt(createdBy) || 1,
        qcStatus: 'pending'   // All new visits start as pending QC
      }
    });

    res.json({ success: true, visit });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// GET /api/coaching-visits — list visits, optionally filtered by enterpriseId
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

// GET /api/coaching-visits/qc — visits pending QC review
router.get('/qc', async (req, res) => {
  try {
    const visits = await prisma.coachingVisit.findMany({
      where: { qcStatus: 'pending' },
      orderBy: { createdAt: 'desc' },
      include: { enterprise: true }
    });
    res.json(visits);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// PATCH /api/coaching-visits/:id/qc — approve or reject a visit
router.patch('/:id/qc', async (req, res) => {
  try {
    const { status, note } = req.body; // status: 'approved' | 'rejected'
    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'status must be approved or rejected' });
    }

    const visit = await prisma.coachingVisit.update({
      where: { id: parseInt(req.params.id) },
      data: {
        qcStatus: status,
        qcNote: note || null
      }
    });

    res.json({ success: true, visit });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// GET /api/coaching-visits/coach-performance — per-coach metrics
router.get('/coach-performance', async (req, res) => {
  try {
    const visits = await prisma.coachingVisit.findMany({ include: { enterprise: true } });
    const users = await prisma.user.findMany({ where: { role: 'Coach' } });

    const performance = users.map(user => {
      const coachVisits = visits.filter(v => v.createdBy === user.id);
      const enterprises = new Set(coachVisits.map(v => v.enterpriseId));
      const totalVisits = coachVisits.length;
      const avgSessions = enterprises.size > 0 ? (totalVisits / enterprises.size).toFixed(1) : 0;
      const completed = coachVisits.filter(v => v.sessionNo >= 8).length;

      return {
        coachId: user.id,
        coachName: user.name,
        totalVisits,
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

module.exports = router;

