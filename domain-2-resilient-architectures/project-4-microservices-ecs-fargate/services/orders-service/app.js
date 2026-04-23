/**
 * SAA Study Project 2.4 - Orders Microservice
 * Simple Express API representing the Orders domain.
 * Demonstrates inter-service communication: Orders calls Users & Products
 * to enrich order data — a common microservices pattern.
 */

const express = require('express');
const app = express();
app.use(express.json());

const PORT    = process.env.PORT    || 3000;
const SERVICE = process.env.SERVICE_NAME || 'orders';

const orders = [
  {
    id: 'o-001', userId: 'u-001', productId: 'p-001',
    quantity: 2, totalPrice: 99.98, status: 'SHIPPED',
    createdAt: '2026-04-01T09:00:00Z'
  },
  {
    id: 'o-002', userId: 'u-002', productId: 'p-003',
    quantity: 1, totalPrice: 29.99, status: 'PROCESSING',
    createdAt: '2026-04-22T10:30:00Z'
  },
];

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/orders/health', (req, res) => {
  res.json({
    status:    'healthy',
    service:   SERVICE,
    timestamp: new Date().toISOString(),
    container: process.env.HOSTNAME || 'unknown',
  });
});

// ── List all orders ───────────────────────────────────────────────────────────
app.get('/orders', (req, res) => {
  const { status, userId } = req.query;
  let result = orders;
  if (status) result = result.filter(o => o.status === status.toUpperCase());
  if (userId) result = result.filter(o => o.userId === userId);
  console.log(`[${SERVICE}] GET /orders — returning ${result.length} orders`);
  res.json({ service: SERVICE, count: result.length, orders: result });
});

// ── Get single order ──────────────────────────────────────────────────────────
app.get('/orders/:id', (req, res) => {
  const order = orders.find(o => o.id === req.params.id);
  if (!order) {
    return res.status(404).json({ error: 'Order not found', id: req.params.id });
  }
  console.log(`[${SERVICE}] GET /orders/${req.params.id}`);
  res.json({ service: SERVICE, order });
});

// ── Create order ──────────────────────────────────────────────────────────────
app.post('/orders', (req, res) => {
  const { userId, productId, quantity } = req.body;
  if (!userId || !productId || !quantity) {
    return res.status(400).json({ error: 'userId, productId, and quantity are required' });
  }

  // In a real microservices setup you would call:
  //   Users Service   → verify the user exists
  //   Products Service → verify stock and get price
  // Here we simulate with a fixed price for simplicity
  const unitPrice  = 29.99;
  const totalPrice = parseFloat((unitPrice * quantity).toFixed(2));

  const newOrder = {
    id:         `o-${Date.now()}`,
    userId,
    productId,
    quantity,
    totalPrice,
    status:     'PENDING',
    createdAt:  new Date().toISOString(),
  };

  orders.push(newOrder);
  console.log(`[${SERVICE}] POST /orders — created ${newOrder.id} for user ${userId}`);

  res.status(201).json({ service: SERVICE, order: newOrder });
});

// ── Update order status ───────────────────────────────────────────────────────
app.patch('/orders/:id/status', (req, res) => {
  const order = orders.find(o => o.id === req.params.id);
  if (!order) {
    return res.status(404).json({ error: 'Order not found' });
  }
  const validStatuses = ['PENDING', 'PROCESSING', 'SHIPPED', 'DELIVERED', 'CANCELLED'];
  const { status } = req.body;
  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: `Status must be one of: ${validStatuses.join(', ')}` });
  }
  order.status = status;
  console.log(`[${SERVICE}] PATCH /orders/${order.id}/status → ${status}`);
  res.json({ service: SERVICE, order });
});

app.listen(PORT, () => {
  console.log(`[${SERVICE}] Orders Service running on port ${PORT}`);
});
