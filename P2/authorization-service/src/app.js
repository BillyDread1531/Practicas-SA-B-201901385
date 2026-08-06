const express = require('express');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const port = process.env.PORT || 3002;

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'authorization-service' });
});

app.post('/authorize', (req, res) => {
  const { role, requiredRole } = req.body;

  if (!role || !requiredRole) {
    return res.status(400).json({ ok: false, message: 'role y requiredRole son requeridos' });
  }

  const allowed = role === 'Admin' || requiredRole === 'Cliente';

  res.json({ ok: true, allowed });
});

app.listen(port, () => {
  console.log(`🔐 Authorization service corriendo en http://localhost:${port}`);
});
