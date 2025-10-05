const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');

const app = express();
const PORT = 3001;

// Enable CORS for all routes
app.use(cors());

// Proxy FileMaker API requests
app.use('/fmi', createProxyMiddleware({
  target: 'https://devdb.sphereemr.com',
  changeOrigin: true,
  secure: true,
  onError: (err, req, res) => {
    console.error('Proxy error:', err);
    res.status(500).json({ error: 'Proxy error' });
  }
}));

app.listen(PORT, () => {
  console.log(`Proxy server running on http://localhost:${PORT}`);
  console.log('FileMaker API requests will be proxied to https://devdb.sphereemr.com');
});
