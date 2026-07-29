const { Router } = require('express');
const asyncHandler = require('../utils/asyncHandler');
const requestsController = require('../controllers/requests.controller');

const router = Router();

router.get('/', asyncHandler(requestsController.getAll));
router.get('/:id', asyncHandler(requestsController.getById));
router.post('/', asyncHandler(requestsController.create));
router.put('/:id', asyncHandler(requestsController.updateFull));
router.patch('/:id/estado', asyncHandler(requestsController.updateEstado));
router.delete('/:id', asyncHandler(requestsController.remove));

module.exports = router;