const express = require('express');
const router = express.Router();
const externalApi = require('../services/externalApi');

// GET /api/external/data
router.get('/data', async (req, res) => {
    try {
        const data = await externalApi.getData('/data');
        res.json(data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// POST /api/external/data
router.post('/data', async (req, res) => {
    try {
        const data = await externalApi.postData('/data', req.body);
        res.json(data);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;