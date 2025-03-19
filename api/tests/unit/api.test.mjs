import { expect } from 'chai';
import request from 'supertest';
import { createRequire } from 'module';

const require = createRequire(import.meta.url);
const app = require('../../src/index.js');

const TEST_PORT = 5001;
let server;

describe('API Endpoints', () => {
    before((done) => {
        server = app.listen(TEST_PORT, () => {
            console.log(`Test server running on port ${TEST_PORT}`);
            done();
        });
    });

    after((done) => {
        server.close(done);
    });

    beforeEach(async () => {
        await request(app)
            .post('/api/reset')
            .expect(200);
    });

    describe('Health Check', () => {
        it('GET /health should return healthy status', async () => {
            const res = await request(app)
                .get('/health')
                .expect(200);
                
            expect(res.body).to.have.property('status', 'healthy');
            expect(res.body).to.have.property('environment', 'test');
            expect(res.body).to.have.property('timestamp');
        });
    });

    describe('Items API', () => {
        describe('GET /api/items', () => {
            it('should return all items', async () => {
                const res = await request(app)
                    .get('/api/items')
                    .expect(200);
                    
                expect(res.body).to.be.an('array');
                expect(res.body).to.have.length(2);
            });
        });

        describe('GET /api/items/:id', () => {
            it('should return a single item', async () => {
                const res = await request(app)
                    .get('/api/items/1')
                    .expect(200);
                    
                expect(res.body).to.have.property('id', 1);
                expect(res.body).to.have.property('name', 'Item 1');
            });

            it('should return 404 for non-existent item', async () => {
                const res = await request(app)
                    .get('/api/items/999')
                    .expect(404);
                    
                expect(res.body).to.have.property('error', 'Item not found');
            });

            it('should handle invalid id parameter', async () => {
                await request(app)
                    .get('/api/items/invalid')
                    .expect(404);
            });
        });

        describe('POST /api/items', () => {
            it('should create a new item', async () => {
                const newItem = { name: 'Test Item' };
                const res = await request(app)
                    .post('/api/items')
                    .send(newItem)
                    .expect(201);
                    
                expect(res.body).to.have.property('name', newItem.name);
                expect(res.body).to.have.property('id');
            });

            it('should validate required fields', async () => {
                const invalidItem = { invalid: 'data' };
                const res = await request(app)
                    .post('/api/items')
                    .send(invalidItem)
                    .expect(400);
                    
                expect(res.body).to.have.property('error', 'Validation error');
            });

            it('should validate name type', async () => {
                const invalidItem = { name: 123 };
                const res = await request(app)
                    .post('/api/items')
                    .send(invalidItem)
                    .expect(400);
                    
                expect(res.body).to.have.property('error', 'Validation error');
            });
        });

        describe('DELETE /api/items/:id', () => {
            it('should delete an existing item', async () => {
                const res = await request(app)
                    .delete('/api/items/1')
                    .expect(200);
                    
                expect(res.body).to.have.property('message', 'Item deleted');
                expect(res.body.item).to.have.property('id', 1);

                // Verify item is gone
                await request(app)
                    .get('/api/items/1')
                    .expect(404);
            });

            it('should return 404 for non-existent item', async () => {
                const res = await request(app)
                    .delete('/api/items/999')
                    .expect(404);
                    
                expect(res.body).to.have.property('error', 'Item not found');
            });
        });
    });
});