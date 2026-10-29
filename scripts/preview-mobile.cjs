const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../apps/mobile/build/web');
const mime = {'.html':'text/html; charset=utf-8','.js':'application/javascript',
  '.wasm':'application/wasm','.json':'application/json','.png':'image/png',
  '.svg':'image/svg+xml','.ttf':'font/ttf','.otf':'font/otf'};
if (!fs.existsSync(path.join(root,'index.html'))) {
  console.error('Chưa có bản web. Chạy scripts/flutter.ps1 build web --release trước.');
  process.exit(1);
}
http.createServer((req,res) => {
  let pathname;
  try { pathname = decodeURIComponent(new URL(req.url,'http://localhost').pathname); }
  catch { res.writeHead(400); res.end('Bad request'); return; }
  let target = path.resolve(root, '.' + pathname);
  const relative = path.relative(root,target);
  if (relative.startsWith('..') || path.isAbsolute(relative)) {
    res.writeHead(403);res.end('Forbidden');return;
  }
  if (pathname.endsWith('/')) target = path.join(target,'index.html');
  fs.readFile(target,(error,bytes) => {
    if (error) { res.writeHead(404);res.end('Not found');return; }
    res.writeHead(200,{'Content-Type':mime[path.extname(target)] || 'application/octet-stream',
      'Cache-Control':'no-cache','Cross-Origin-Opener-Policy':'same-origin',
      'Cross-Origin-Embedder-Policy':'require-corp'});
    res.end(bytes);
  });
}).listen(5174,'127.0.0.1',()=>console.log('Little Island: http://localhost:5174'));
