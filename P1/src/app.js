const express = require('express');
const apiRouter = require('./routes');
const errorMiddleware = require('./middlewares/error.middleware');

const app = express();

app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.use('/api/v1', apiRouter);
app.use(errorMiddleware);

module.exports = app;
