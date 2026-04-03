const express = require('express');
const router = express.Router();
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, '..', 'uploads');
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

// Multer config — store files on disk with original extension
const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadDir),
  filename: (req, file, cb) => {
    // Unique filename: timestamp + random + original extension
    const ext = path.extname(file.originalname);
    cb(null, `evidence_${Date.now()}_${Math.random().toString(36).slice(2)}${ext}`);
  }
});

// Only allow image files
const fileFilter = (req, file, cb) => {
  const allowed = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp'];
  if (allowed.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error('Only image files are allowed'), false);
  }
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB max per photo
});

// POST /api/upload/photo — upload a single evidence photo
// Returns the server URL to store in evidenceUrls[]
router.post('/photo', upload.single('photo'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }

  // Build the public URL — frontend will use this to display/store the photo
  const serverUrl = `${req.protocol}://${req.get('host')}/uploads/${req.file.filename}`;
  res.json({ success: true, url: serverUrl, filename: req.file.filename });
});

// POST /api/upload/photos — upload multiple photos at once (max 5)
router.post('/photos', upload.array('photos', 5), (req, res) => {
  if (!req.files || req.files.length === 0) {
    return res.status(400).json({ error: 'No files uploaded' });
  }

  const urls = req.files.map(f => `${req.protocol}://${req.get('host')}/uploads/${f.filename}`);
  res.json({ success: true, urls });
});

module.exports = router;
