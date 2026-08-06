const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const { encrypt, decrypt } = require('../utils/aes');

function getTokenMaxAge() {
  const expiration = process.env.JWT_EXPIRATION || '15m';
  const match = expiration.match(/^(\d+)([smhd])$/i);

  if (!match) {
    return 15 * 60 * 1000;
  }

  const [, amount, unit] = match;
  const multipliers = {
    s: 1000,
    m: 60 * 1000,
    h: 60 * 60 * 1000,
    d: 24 * 60 * 60 * 1000,
  };

  return Number(amount) * multipliers[unit.toLowerCase()];
}

async function register(req, res, next) {
  try {
    const { name, email, password, role = 'Cliente' } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ ok: false, message: 'Faltan datos obligatorios' });
    }

    const encryptedName = encrypt(name);
    const encryptedEmail = encrypt(email);
    const encryptedPassword = encrypt(password);

    const query = `
      INSERT INTO usuarios (nombre, correo, password, rol)
      VALUES ($1, $2, $3, $4)
      RETURNING id, nombre, correo, rol
    `;

    const result = await db.query(query, [encryptedName, encryptedEmail, encryptedPassword, role]);

    res.status(201).json({
      ok: true,
      message: 'Usuario registrado correctamente',
      user: result.rows[0],
    });
  } catch (error) {
    next(error);
  }
}

async function login(req, res, next) {
  try {
    const { email, password } = req.body;

    const query = 'SELECT * FROM usuarios';
    const result = await db.query(query);

    const user = result.rows.find((row) => {
      try {
        return decrypt(row.correo) === email;
      } catch (error) {
        return false;
      }
    });

    if (!user) {
      return res.status(401).json({ ok: false, message: 'Credenciales inválidas' });
    }

    let isValid = false;

    try {
      isValid = decrypt(user.password) === password;
    } catch (error) {
      isValid = await bcrypt.compare(password, user.password);
    }

    if (!isValid) {
      return res.status(401).json({ ok: false, message: 'Credenciales inválidas' });
    }

    const token = jwt.sign({ id: user.id, role: user.rol }, process.env.JWT_SECRET, {
      expiresIn: process.env.JWT_EXPIRATION || '15m',
    });

    res.cookie('token', token, {
      httpOnly: true,
      sameSite: 'lax',
      secure: false,
      maxAge: getTokenMaxAge(),
    });

    res.json({ ok: true, message: 'Login exitoso', role: user.rol });
  } catch (error) {
    next(error);
  }
}

module.exports = { register, login };
