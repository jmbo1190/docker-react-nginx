const axios = require('axios');

const API_BASE_URL = process.env.EXTERNAL_API_URL || 'https://api.example.com';

class ExternalApiService {
    constructor() {
        this.client = axios.create({
            baseURL: API_BASE_URL,
            timeout: 5000,
            headers: {
                'Content-Type': 'application/json',
                // Add any API keys or auth tokens here
                'Authorization': `Bearer ${process.env.EXTERNAL_API_KEY}`
            }
        });
    }

    async getData(path) {
        try {
            const response = await this.client.get(path);
            return response.data;
        } catch (error) {
            console.error('External API error:', error.message);
            throw new Error('External API request failed');
        }
    }

    async postData(path, data) {
        try {
            const response = await this.client.post(path, data);
            return response.data;
        } catch (error) {
            console.error('External API error:', error.message);
            throw new Error('External API request failed');
        }
    }
}

module.exports = new ExternalApiService();