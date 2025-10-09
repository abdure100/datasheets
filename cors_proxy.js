const http = require('http');
const https = require('https');
const url = require('url');

const PORT = 3002;

const server = http.createServer((req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, PATCH, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, Accept, Cache-Control');
  
  if (req.method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  // Parse the target URL - prepend FileMaker domain
  const targetUrl = 'https://devdb.sphereemr.com' + req.url;
  const parsedUrl = url.parse(targetUrl);
  
  console.log(`Proxying ${req.method} ${req.url} to ${targetUrl}`);
  
  const options = {
    hostname: parsedUrl.hostname,
    port: parsedUrl.port || (parsedUrl.protocol === 'https:' ? 443 : 80),
    path: parsedUrl.path,
    method: req.method,
    headers: {
      ...req.headers,
      host: parsedUrl.hostname,
    }
  };

  const proxyReq = (parsedUrl.protocol === 'https:' ? https : http).request(options, (proxyRes) => {
    // Override CORS headers to ensure they're correct
    const headers = { ...proxyRes.headers };
    headers['Access-Control-Allow-Origin'] = '*';
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, PATCH, OPTIONS';
    headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, Accept';
    
    res.writeHead(proxyRes.statusCode, headers);
    proxyRes.pipe(res);
  });

  proxyReq.on('error', (err) => {
    console.error('Proxy error:', err);
    res.writeHead(500);
    res.end('Proxy error: ' + err.message);
  });

  req.pipe(proxyReq);
});

server.listen(PORT, () => {
  console.log(`CORS proxy server running on http://localhost:${PORT}`);
  console.log('Usage: http://localhost:3002/fmi/data/v1/databases/EIDBI/sessions');
  console.log('Will proxy to: https://devdb.sphereemr.com/fmi/data/v1/databases/EIDBI/sessions');
});
