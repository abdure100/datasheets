// proxy.js
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

// We mount at /fmi, and we target https://devdb.sphereemr.com/fmi
// Then we REWRITE the prefix "^/fmi" → "" so upstream receives "/data/v1/..."
app.use('/fmi', createProxyMiddleware({
  target: 'https://devdb.sphereemr.com/fmi',
  changeOrigin: true,          // sets Host/SNI to devdb.sphereemr.com
  secure: true,                // set false only if upstream cert is self-signed
  selfHandleResponse: false,   // pass FM response body as-is (incl. messages[])
  logLevel: 'debug',
  xfwd: true,
  pathRewrite: (path) => {
    const out = path.replace(/^\/fmi/, ''); // e.g. /fmi/data/... → /data/...
    return out;
  },
  onProxyReq(proxyReq, req) {
    proxyReq.setHeader('Host', 'devdb.sphereemr.com'); // ensure exact vhost
    console.log('→', req.method, req.originalUrl, '   (upstream path after rewrite)');
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

const PORT = 8080;
app.listen(PORT, () => console.log(`Proxy on http://localhost:${PORT}`));