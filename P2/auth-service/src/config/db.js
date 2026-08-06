const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || 'practica2',
  user: process.env.DB_USER || 'postgres',
  password: String(process.env.DB_PASSWORD || '12345'),
});

module.exports = pool;
