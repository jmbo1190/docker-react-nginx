require('dotenv').config();
const express = require('express');
const cors = require('cors');
const routes = require('./routes');
const healthRoutes = require('./routes/health');
const errorHandler = require('./middleware/errorHandler');
const jsonPlaceholderApi = require('./services/jsonPlaceholderApi');
const { createRouter } = require('./routes/jsonPlaceholder');

const app = express();
const port = process.env.PORT || 5000;

// Basic middleware
app.use(cors());
app.use(express.json());

// Mount health check route at root level
app.use('/health', healthRoutes);

// API routes under /api prefix
app.use('/api', routes);
app.use('/jsonplaceholder', createRouter(jsonPlaceholderApi)); // Remove /api prefix here

// Error handling
app.use(errorHandler);

// Only start the server if we're not being required by another module (like tests)
if (!module.parent) {
    const server = app.listen(port)
        .on('error', (err) => {
            if (err.code === 'EADDRINUSE') {
                console.error(`Port ${port} is already in use. Using port ${port + 1}`);
                app.listen(port + 1);
            } else {
                console.error('Server error:', err);
            }
        })
        .on('listening', () => {
            const actualPort = server.address().port;
            console.log(`API server running on port ${actualPort} in ${process.env.NODE_ENV} mode`);
            console.log(`Health check available at http://localhost:${actualPort}/health`);
        });
}

module.exports = app;