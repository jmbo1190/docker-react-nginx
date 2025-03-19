const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
    console.log('Health check requested at:', new Date().toISOString());
    
    try {
        res.status(200).json({
            status: 'healthy',
            timestamp: new Date().toISOString(),
            environment: process.env.NODE_ENV || 'development',
            version: process.env.API_VERSION || '1.0.0',
            pid: process.pid
        });
        console.log('Health check succeeded');
    } catch (error) {
        console.error('Health check failed:', error);
        res.status(500).json({ status: 'error', error: error.message });
    }
});

router.get('/timestamp', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        timestamp: new Date().toISOString()
    });
});

module.exports = router;