/**
 * SAA Study Project 2.4 - Products Microservice
 * Simple Express API representing the Products domain.
 * ALB routes /products/* to this service's target group.
 */

const express = require('express');
const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;
const SERVICE = process.env.SERVICE_NAME || 'products';

const products = [
  { id: 'p-001', name: 'AWS Study Guide',         category: 'books',    price: 49.99, stock: 150 },
  { id: 'p-002', name: 'Cloud Architecture Poster',category: 'posters',  price: 19.99, stock: 75  },
  { id: 'p-003', name: 'SAA Practice Exam Pack',   category: 'digital',  price: 29.99, stock: 999 },
  { id: 'p-004', name: 'AWS Sticker Sheet',         category: 'merch',    price:  9.99, stock: 200 },
];

// ── Health check ──────────────────────────────────────────────────────────────
app.get('/products/health', (req, res) => {
  res.json({
    status:    'healthy',
    service:   SERVICE,
    timestamp: new Date().toISOString(),
    container: process.env.HOSTNAME || 'unknown',
  });
});

// ── List all products (optional category filter) ──────────────────────────────
app.get('/products', (req, res) => {
  const { category } = req.query;
  const result = category
    ? products.filter(p => p.category === category)
    : products;
  console.log(`[${SERVICE}] GET /products — returning ${result.length} products`);
  res.json({ service: SERVICE, count: result.length, products: result });
});

// ── Get single product ────────────────────────────────────────────────────────
app.get('/products/:id', (req, res) => {
  const product = products.find(p => p.id === req.params.id);
  if (!product) {
    return res.status(404).json({ error: 'Product not found', id: req.params.id });
  }
  console.log(`[${SERVICE}] GET /products/${req.params.id} — ${product.name}`);
  res.json({ service: SERVICE, product });
});

// ── Update stock ──────────────────────────────────────────────────────────────
app.patch('/products/:id/stock', (req, res) => {
  const product = products.find(p => p.id === req.params.id);
  if (!product) {
    return res.status(404).json({ error: 'Product not found' });
  }
  const { adjustment } = req.body;
  product.stock += adjustment;
  console.log(`[${SERVICE}] PATCH /products/${req.params.id}/stock — new stock: ${product.stock}`);
  res.json({ service: SERVICE, product });
});

app.listen(PORT, () => {
  console.log(`[${SERVICE}] Products Service running on port ${PORT}`);
});
