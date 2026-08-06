const express = require('express');
const { register, login } = require('../controllers/auth.controller');
const authMiddleware = require('../middlewares/auth.middleware');

const router = express.Router();

router.post('/register', register);
router.post('/login', login);
router.get('/me', authMiddleware(), (req, res) => {
  res.json({ ok: true, user: req.user });
});
router.get('/admin-only', authMiddleware('Admin'), (req, res) => {
  res.json({ ok: true, message: 'Acceso permitido solo para administradores', user: req.user });
});
router.get('/dashboard', authMiddleware(), (req, res) => {
  res.json({ ok: true, message: 'Acceso permitido para admin y cliente', user: req.user });
});

module.exports = router;
