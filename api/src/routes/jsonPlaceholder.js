const express = require('express');
const jsonPlaceholderApi = require('../services/jsonPlaceholderApi');

function createRouter(api) {
    const router = express.Router();

    // GET /api/jsonplaceholder/posts
    router.get('/posts', async (req, res, next) => {
        try {
            const posts = await api.getPosts();
            res.json(posts);
        } catch (error) {
            next(error);
        }
    });

    // GET /api/jsonplaceholder/posts/:id
    router.get('/posts/:id', async (req, res, next) => {
        try {
            const post = await api.getPost(req.params.id);
            if (!post) {
                return res.status(404).json({ error: 'Post not found' });
            }
            res.json(post);
        } catch (error) {
            next(error);
        }
    });

    // POST /api/jsonplaceholder/posts
    router.post('/posts', async (req, res, next) => {
        try {
            const newPost = await api.createPost(req.body);
            res.status(201).json(newPost);
        } catch (error) {
            next(error);
        }
    });

    // GET /api/jsonplaceholder/posts/:id/comments
    router.get('/posts/:id/comments', async (req, res, next) => {
        try {
            const comments = await api.getComments(req.params.id);
            res.json(comments);
        } catch (error) {
            next(error);
        }
    });

    return router;
}

module.exports = { createRouter };