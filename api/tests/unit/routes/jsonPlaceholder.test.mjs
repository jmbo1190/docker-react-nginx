import request from 'supertest';
import { expect } from 'chai';
import express from 'express';
import { createRouter } from '../../../src/routes/jsonPlaceholder.js';

describe('JsonPlaceholder Router', () => {
    let app;
    let mockApi;
    
    // Test data
    const testPosts = [
        { id: 1, title: 'Post 1', body: 'Content 1' },
        { id: 2, title: 'Post 2', body: 'Content 2' }
    ];
    
    const testComments = [
        { id: 1, postId: 1, body: 'Comment 1' },
        { id: 2, postId: 1, body: 'Comment 2' }
    ];

    beforeEach(() => {
        // Create mock API
        mockApi = {
            getPosts: async () => testPosts,
            getPost: async (id) => testPosts.find(p => p.id === parseInt(id)),
            createPost: async (data) => ({ id: 3, ...data }),
            getComments: async () => testComments
        };

        // Setup app with mocked API
        app = express();
        app.use(express.json());
        app.use('/api', createRouter(mockApi));
    });

    describe('GET /api/posts', () => {
        it('should return all posts', async () => {
            const response = await request(app)
                .get('/api/posts')
                .expect(200);

            expect(response.body).to.deep.equal(testPosts);
        });

        it('should handle errors', async () => {
            mockApi.getPosts = async () => { throw new Error('API Error'); };

            await request(app)
                .get('/api/posts')
                .expect(500);
        });
    });

    describe('GET /api/posts/:id', () => {
        it('should return a single post', async () => {
            const response = await request(app)
                .get('/api/posts/1')
                .expect(200);

            expect(response.body).to.deep.equal(testPosts[0]);
        });

        it('should handle errors', async () => {
            mockApi.getPost = async () => { throw new Error('API Error'); };

            await request(app)
                .get('/api/posts/999')
                .expect(500);
        });
    });

    describe('POST /api/posts', () => {
        it('should create a new post', async () => {
            const newPost = { title: 'New Post', body: 'New Content' };
            const createdPost = { id: 3, ...newPost };

            const response = await request(app)
                .post('/api/posts')
                .send(newPost)
                .expect(201);

            expect(response.body).to.deep.equal(createdPost);
        });

        it('should handle errors', async () => {
            mockApi.createPost = async () => { throw new Error('API Error'); };

            await request(app)
                .post('/api/posts')
                .send({ title: 'Bad Post' })
                .expect(500);
        });
    });

    describe('GET /api/posts/:id/comments', () => {
        it('should return comments for a post', async () => {
            const response = await request(app)
                .get('/api/posts/1/comments')
                .expect(200);

            expect(response.body).to.deep.equal(testComments);
        });

        it('should handle errors', async () => {
            mockApi.getComments = async () => { throw new Error('API Error'); };

            await request(app)
                .get('/api/posts/1/comments')
                .expect(500);
        });
    });
});