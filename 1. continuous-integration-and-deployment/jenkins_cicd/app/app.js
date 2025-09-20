const express = require("express");
const client = require('prom-client');

const app = express();
const register = new client.Registry();

// Collect Node.js process & runtime metrics
client.collectDefaultMetrics({ register });

// Example counter for requests
const httpRequestCounter = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests received',
  labelNames: ['method', 'path']
});
register.registerMetric(httpRequestCounter);

// Count every request
app.use((req, res, next) => {
  httpRequestCounter.labels(req.method, req.path).inc();
  next();
});


// Normal route
app.get('/', (req, res) => {
  res.send('Hello from Node.js app on kubernetes with Prometheus metrics!');
});


// Metrics route
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`App running on port ${PORT}`);
});







