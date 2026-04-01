const express = require('express');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());

app.get('/health', (_req, res) => {
  res.status(200).json({
    status: 'ok',
    service: 'vitalsync-backend',
    uptime: process.uptime(),
    checkedAt: new Date().toISOString(),
  });
});

app.get('/api/activities', (_req, res) => {
  res.status(200).json([
    { id: 1, type: 'running', duration: 30, date: '2026-03-28' },
    { id: 2, type: 'cycling', duration: 45, date: '2026-03-29' },
    { id: 3, type: 'swimming', duration: 60, date: '2026-03-30' },
  ]);
});

if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`VitalSync backend listening on port ${PORT}`);
  });
}

module.exports = app;
