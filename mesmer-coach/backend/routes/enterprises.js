const express = require('express');
const router = express.Router();
const prisma = require('../prisma/client');

router.get('/', async (req, res) => {
  const enterprises = await prisma.enterprise.findMany();
  res.json(enterprises);
});

router.post('/', async (req, res) => {
  const data = req.body;
  const enterprise = await prisma.enterprise.create({ data });
  res.json(enterprise);
});

module.exports = router;
