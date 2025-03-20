const axios = require('axios');

const baseURL = 'https://jsonplaceholder.typicode.com';

module.exports = {
    getPosts: async () => {
        const response = await axios.get(`${baseURL}/posts`);
        return response.data;
    },
    async getPost(id) {
        try {
            const response = await axios.get(`${baseURL}/posts/${id}`);
            return response.data;
        } catch (error) {
            console.error('JSONPlaceholder API error:', error.message);
            throw new Error(`Failed to fetch post ${id}`);
        }
    },
    async createPost(data) {
        try {
            const response = await axios.post(`${baseURL}/posts`, data);
            return response.data;
        } catch (error) {
            console.error('JSONPlaceholder API error:', error.message);
            throw new Error('Failed to create post');
        }
    },
    async getComments(postId) {
        try {
            const response = await axios.get(`${baseURL}/posts/${postId}/comments`);
            return response.data;
        } catch (error) {
            console.error('JSONPlaceholder API error:', error.message);
            throw new Error(`Failed to fetch comments for post ${postId}`);
        }
    }
};