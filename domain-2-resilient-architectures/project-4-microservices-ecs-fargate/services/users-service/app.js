/**
 * SAA Study Project 2.4 - Users Microservice
 * Simple Express API representing the Users domain.
 * Designed to run as a Fargate container behind an ALB.
 */

const express = require('express');
const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const SERVICE = process.env.SERVICE_NAME || 'users';

// In-memory store (replace with DynamoDB in production)
const users = [
  { id: 'u-001', name: 'Alice Johnson', email: 'alice@example.com', tier: 'premium' },
  { id: 'u-002', name: 'Bob Smith',     email: 'bob@example.com',   tier: 'standard' },
  { id: 'u-003', name: 'Carol White',   email: 'carol@example.com', tier: 'premium' },
];

// ── Health check — required for ALB target group health checks ──────────────
app.get('/users/health', (req, res) => {
  res.json({
    status:    'healthy',
    service:   SERVICE,
    timestamp: new Date().toISOString(),
    container: process.env.HOSTNAME || 'unknown',   // ECS task ID
  });
});

// ── List all users ────────────────────────────────────────────────────────────
app.get('/users', (req, res) => {
  console.log(`[${SERVICE}] GET /users — returning ${users.length} users`);
  res.json({ service: SERVICE, count: users.length, users });
});

// ── Get single user ───────────────────────────────────────────────────────────
app.get('/users/:id', (req, res) => {
  const user = users.find(u => u.id === req.params.id);
  if (!user) {
    return res.status(404).json({ error: 'User not found', id: req.params.id });
  }
  console.log(`[${SERVICE}] GET /users/${req.params.id} — found ${user.name}`);
  res.json({ service: SERVICE, user });
});

// ── Create user ───────────────────────────────────────────────────────────────
app.post('/users', (req, res) => {
  const { name, email, tier = 'standard' } = req.body;
  if (!name || !email) {
    return res.status(400).json({ error: 'name and email are required' });
  }
  const newUser = { id: `u-${Date.now()}`, name, email, tier };
  users.push(newUser);
  console.log(`[${SERVICE}] POST /users — created ${name}`);
  res.status(201).json({ service: SERVICE, user: newUser });
});

app.listen(PORT, () => {
  console.log(`[${SERVICE}] Users Service running on port ${PORT}`);
  console.log(`[${SERVICE}] Container: ${process.env.HOSTNAME || 'local'}`);
});
