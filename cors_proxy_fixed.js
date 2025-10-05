const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();

// Handle CORS preflight requests BEFORE the proxy
app.use((req, res, next) => {
  // Set CORS headers for all requests
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept, User-Agent');
  
  // Handle preflight OPTIONS requests
  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }
  next();
});

// ✅ Mount the proxy AFTER CORS handling
app.use('/fmi',
  createProxyMiddleware({
    target: 'https://devdb.sphereemr.com',
    changeOrigin: true,
    secure: true,
    // Let the proxy return FM's body as-is (including error messages[])
    selfHandleResponse: false,
    logLevel: 'warn',
    onProxyReq: (proxyReq, req, res) => {
      console.log(`Proxying ${req.method} ${req.url} to ${proxyReq.path}`);
    },
    onProxyRes: (proxyRes, req, res) => {
      // Override CORS headers to ensure they're correct
      proxyRes.headers['Access-Control-Allow-Origin'] = '*';
      proxyRes.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, PATCH, OPTIONS';
      proxyRes.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, Accept, User-Agent';
    },
    onError: (err, req, res) => {
      console.error('Proxy error:', err);
      res.status(500).json({ error: 'Proxy request error' });
    }
  })
);

// (Optionally) your parsers for the rest of the app
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const PORT = 3002;
app.listen(PORT, () => {
  console.log(`Fixed CORS proxy server running on http://localhost:${PORT}`);
  console.log('Usage: http://localhost:3002/fmi/data/v1/databases/EIDBI/sessions');
  console.log('Will proxy to: https://devdb.sphereemr.com/fmi/data/v1/databases/EIDBI/sessions');
});
