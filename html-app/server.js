/**
 * server.js — Local HTTP server สำหรับทดสอบ Motor-insurance-quote_V12.html
 * 
 * วิธีใช้:
 *   node server.js
 *   แล้วเปิด http://localhost:3000
 * 
 * ต้องการ Node.js เท่านั้น ไม่ต้อง install package เพิ่ม
 */

const http = require('http');
const fs   = require('fs');
const path = require('path');

const PORT = 3000;
const ROOT = __dirname;  // โฟลเดอร์ที่ server.js อยู่

const MIME = {
    '.html': 'text/html; charset=utf-8',
    '.js':   'application/javascript; charset=utf-8',
    '.json': 'application/json; charset=utf-8',
    '.css':  'text/css; charset=utf-8',
    '.png':  'image/png',
    '.jpg':  'image/jpeg',
    '.svg':  'image/svg+xml',
    '.ico':  'image/x-icon',
    '.txt':  'text/plain; charset=utf-8',
};

const server = http.createServer((req, res) => {
    // ตัด query string ออก
    let urlPath = req.url.split('?')[0];

    // default page
    if (urlPath === '/' || urlPath === '') {
        urlPath = '/Motor-insurance-quote_V12.html';
    }

    // Security: ป้องกัน path traversal
    const safePath = path.normalize(urlPath).replace(/^(\.\.[/\\])+/, '');
    const filePath = path.join(ROOT, safePath);

    // ต้องอยู่ใน ROOT เท่านั้น
    if (!filePath.startsWith(ROOT)) {
        res.writeHead(403); res.end('Forbidden'); return;
    }

    fs.readFile(filePath, (err, data) => {
        if (err) {
            if (err.code === 'ENOENT') {
                res.writeHead(404, { 'Content-Type': 'text/plain; charset=utf-8' });
                res.end(`404 Not Found: ${safePath}`);
            } else {
                res.writeHead(500); res.end('Server Error');
            }
            return;
        }

        const ext  = path.extname(filePath).toLowerCase();
        const mime = MIME[ext] || 'application/octet-stream';

        res.writeHead(200, {
            'Content-Type':  mime,
            'Cache-Control': 'no-cache',          // ไม่ cache ขณะ dev
        });
        res.end(data);

        console.log(`[${new Date().toLocaleTimeString('th-TH')}] ${req.method} ${urlPath}`);
    });
});

server.listen(PORT, '127.0.0.1', () => {
    console.log('');
    console.log('  ✅ Local server พร้อมใช้งาน');
    console.log(`  🌐 เปิด browser ที่:  http://localhost:${PORT}`);
    console.log(`  📄 ไฟล์หลัก:          Motor-insurance-quote_V12.html`);
    console.log('');
    console.log('  กด Ctrl+C เพื่อหยุด server');
    console.log('');
});

server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
        console.error(`\n  ❌ Port ${PORT} ถูกใช้งานอยู่แล้ว`);
        console.error(`     ลองเปลี่ยน PORT ใน server.js หรือปิดโปรแกรมที่ใช้ port นั้น\n`);
    } else {
        console.error('Server error:', err);
    }
    process.exit(1);
});
