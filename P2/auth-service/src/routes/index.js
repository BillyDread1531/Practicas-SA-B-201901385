const express = require('express');
const authRoutes = require('./auth.routes');

const router = express.Router();

router.get('/health', (req, res) => {
  res.json({ ok: true, service: 'auth-service' });
});

router.use(authRoutes);

module.exports = router;
