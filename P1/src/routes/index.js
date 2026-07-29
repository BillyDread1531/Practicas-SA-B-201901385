const { Router } = require('express');

const requestsRouter = require('./requests.routes');

const router = Router();

router.use('/requests', requestsRouter);

module.exports = router;