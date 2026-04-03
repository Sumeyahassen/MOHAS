const express = require('express');
const router = express.Router();
const prisma = require('../prisma/client');

// GET /api/graduation/:enterpriseId/check
// Returns the triangulation checklist status for an enterprise.
// Certificate is only unlocked when ALL three criteria pass:
//   1. Baseline assessment exists
//   2. At least 8 approved coaching visits
//   3. At least one visit has evidence photos
router.get('/:enterpriseId/check', async (req, res) => {
  try {
    const enterpriseId = parseInt(req.params.enterpriseId);

    // 1. Check baseline assessment exists
    const baseline = await prisma.assessment.findFirst({
      where: { enterpriseId, type: 'baseline' }
    });

    // 2. Count approved coaching visits
    const approvedVisits = await prisma.coachingVisit.findMany({
      where: { enterpriseId, qcStatus: 'approved' }
    });

    // 3. Check if any visit has evidence photos uploaded to server
    const hasEvidence = approvedVisits.some(
      v => Array.isArray(v.evidenceUrls) && v.evidenceUrls.length > 0
    );

    const checklist = {
      hasBaseline: !!baseline,
      completedVisits: approvedVisits.length,
      requiredVisits: 8,
      hasEvidence,
      // All three must pass to unlock certificate
      canGraduate: !!baseline && approvedVisits.length >= 8 && hasEvidence
    };

    // If eligible, upsert the graduation record
    if (checklist.canGraduate) {
      await prisma.graduation.upsert({
        where: { enterpriseId },
        update: {
          hasBaseline: true,
          completedVisits: approvedVisits.length,
          hasEvidence: true
        },
        create: {
          enterpriseId,
          hasBaseline: true,
          completedVisits: approvedVisits.length,
          hasEvidence: true,
          certificateIssued: false
        }
      });
    }

    res.json(checklist);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

// POST /api/graduation/:enterpriseId/issue-certificate
// Marks the certificate as issued after supervisor confirms
router.post('/:enterpriseId/issue-certificate', async (req, res) => {
  try {
    const enterpriseId = parseInt(req.params.enterpriseId);

    // Re-verify eligibility before issuing
    const baseline = await prisma.assessment.findFirst({
      where: { enterpriseId, type: 'baseline' }
    });
    const approvedVisits = await prisma.coachingVisit.count({
      where: { enterpriseId, qcStatus: 'approved' }
    });
    const visitsWithEvidence = await prisma.coachingVisit.findFirst({
      where: {
        enterpriseId,
        qcStatus: 'approved',
        evidenceUrls: { isEmpty: false }
      }
    });

    if (!baseline || approvedVisits < 8 || !visitsWithEvidence) {
      return res.status(400).json({
        error: 'Enterprise does not meet graduation criteria',
        details: {
          hasBaseline: !!baseline,
          approvedVisits,
          hasEvidence: !!visitsWithEvidence
        }
      });
    }

    const graduation = await prisma.graduation.upsert({
      where: { enterpriseId },
      update: { certificateIssued: true, graduatedAt: new Date() },
      create: {
        enterpriseId,
        hasBaseline: true,
        completedVisits: approvedVisits,
        hasEvidence: true,
        certificateIssued: true,
        graduatedAt: new Date()
      }
    });

    res.json({ success: true, graduation });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
