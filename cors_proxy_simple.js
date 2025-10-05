const express = require('express');
const cors = require('cors');
const { createProxyMiddleware } = require('http-proxy-middleware');

const app = express();

app.use(cors({
  origin: true,
  methods: ['GET','POST','PATCH','PUT','DELETE','OPTIONS'],
  allowedHeaders: ['Content-Type','Authorization','Accept'],
}));

app.get('/health', (req, res) => res.status(200).send('ok'));

// Mount at /fmi. Target is JUST the origin. No path rewrites.
app.use('/fmi', createProxyMiddleware({
  target: 'https://devdb.sphereemr.com',
  changeOrigin: true,          // set Host/SNI to devdb.sphereemr.com
  secure: true,                // keep true unless upstream is self-signed
  selfHandleResponse: false,
  logLevel: 'debug',
  xfwd: true,
  onProxyReq(proxyReq, req) {
    // Force correct upstream host header just in case
    proxyReq.setHeader('Host', 'devdb.sphereemr.com');
    // Show exactly what we're sending
    console.log('→', req.method, req.originalUrl);
  },
  onProxyRes(proxyRes, req) {
    console.log('←', proxyRes.statusCode, req.method, req.originalUrl);
  },
  onError(err, req, res) {
    console.error('proxy error:', err?.message || err);
    res.writeHead(502, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'proxy_error', detail: String(err) }));
  },
}));

const PORT = 3002;
app.listen(PORT, () => console.log(`Proxy on http://localhost:${PORT}`));
