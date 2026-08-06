const express = require('express');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const dotenv = require('dotenv');

dotenv.config();

const db = require('./config/db');
const routes = require('./routes');
const errorMiddleware = require('./middlewares/error.middleware');

const app = express();
const port = process.env.PORT || 3001;

app.use(cors({ origin: true, credentials: true }));
app.use(express.json());
app.use(cookieParser());
app.use('/', routes);
app.use(errorMiddleware);

app.listen(port, async () => {
  try {
    await db.query('SELECT 1');
    console.log('✅ Conexión a PostgreSQL lista');
  } catch (err) {
    console.error('⚠️ Error conectando a PostgreSQL:', err.message);
  }

  console.log(`🚀 Auth service corriendo en http://localhost:${port}`);
});
