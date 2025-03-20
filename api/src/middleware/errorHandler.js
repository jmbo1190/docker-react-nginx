const errorHandler = (err, req, res, next) => {
    console.error('Error:', err);

    if (err.response) {
        // External API error
        return res.status(err.response.status).json({
            error: 'External API error',
            message: err.response.data
        });
    }

    // Default error
    res.status(500).json({
        error: 'Internal Server Error',
        message: err.message
    });
};

module.exports = errorHandler;