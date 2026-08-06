const jwt = require('jsonwebtoken');
const { authorizeWithRetry } = require('../services/authorization.client');

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

function authMiddleware(requiredRole = null) {
  return (req, res, next) => {
    try {
      const token = req.cookies?.token;

      if (!token) {
        return res.status(401).json({ ok: false, message: 'No autenticado' });
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = decoded;

      if (!requiredRole) {
        return next();
      }

      authorizeWithRetry({ role: decoded.role, requiredRole })
        .then((allowed) => {
          if (!allowed) {
            return res.status(403).json({ ok: false, message: 'No autorizado' });
          }

          return next();
        })
        .catch(() => res.status(503).json({ ok: false, message: 'No se pudo validar la autorización' }));
    } catch (error) {
      if (error.name === 'TokenExpiredError') {
        const gracePeriod = Number(process.env.JWT_GRACE_PERIOD?.replace(/[^0-9]/g, '') || 5);
        const now = Math.floor(Date.now() / 1000);
        const expiredAt = error.expiredAt ? Math.floor(error.expiredAt.getTime() / 1000) : now;

        if (now - expiredAt <= gracePeriod) {
          const refreshToken = jwt.sign({
            id: error.payload?.id,
            role: error.payload?.role,
          }, process.env.JWT_SECRET, { expiresIn: process.env.JWT_EXPIRATION || '15m' });

          res.cookie('token', refreshToken, {
            httpOnly: true,
            sameSite: 'lax',
            secure: false,
            maxAge: getTokenMaxAge(),
          });

          req.user = error.payload;
          return next();
        }
      }

      return res.status(401).json({ ok: false, message: 'Token inválido o expirado' });
    }
  };
}

module.exports = authMiddleware;
