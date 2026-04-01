const request = require('supertest');
const app = require('../server');

describe('GET /api/activities', () => {
  it('should return 200 with an array of activities', async () => {
    const res = await request(app).get('/api/activities');

    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThanOrEqual(1);
    expect(res.body[0]).toHaveProperty('type');
    expect(res.body[0]).toHaveProperty('duration');
  });
});
