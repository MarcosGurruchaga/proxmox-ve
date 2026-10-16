const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const ROOT_DIR = 'C:\\vm';

const server = http.createServer((req, res) => {
    // Decode URL
    let reqPath = decodeURI(req.url.split('?')[0]);
    let safePath = path.normalize(path.join(ROOT_DIR, reqPath));

    if (!safePath.startsWith(ROOT_DIR)) {
        res.writeHead(403);
        return res.end('Forbidden');
    }

    fs.stat(safePath, (err, stats) => {
        if (err) {
            res.writeHead(404);
            return res.end('File not found');
        }

        if (stats.isDirectory()) {
            fs.readdir(safePath, { withFileTypes: true }, (err, files) => {
                if (err) {
                    res.writeHead(500);
                    return res.end('Error reading directory');
                }
                res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
                let html = '<html><body><h2>Index of ' + reqPath + '</h2><ul>';
                if (reqPath !== '/' && reqPath !== '') {
                    html += '<li><a href="../">..</a></li>';
                }
                for (const file of files) {
                    let href = path.posix.join(reqPath, file.name);
                    if (file.isDirectory()) href += '/';
                    html += `<li><a href="${encodeURI(href)}">${file.name}</a> ${file.isDirectory() ? '[DIR]' : '(' + (file.size || '') + ' bytes)'}</li>`;
                }
                html += '</ul></body></html>';
                res.end(html);
            });
            return;
        }

        // Streaming file transfer
        const range = req.headers.range;
        if (range) {
            const parts = range.replace(/bytes=/, '').split('-');
            const start = parseInt(parts[0], 10);
            const end = parts[1] ? parseInt(parts[1], 10) : stats.size - 1;
            const chunksize = (end - start) + 1;
            const fileStream = fs.createReadStream(safePath, { start, end });
            res.writeHead(206, {
                'Content-Range': `bytes ${start}-${end}/${stats.size}`,
                'Accept-Ranges': 'bytes',
                'Content-Length': chunksize,
                'Content-Type': 'application/octet-stream',
            });
            fileStream.pipe(res);
        } else {
            res.writeHead(200, {
                'Content-Length': stats.size,
                'Content-Type': 'application/octet-stream',
                'Accept-Ranges': 'bytes',
            });
            fs.createReadStream(safePath).pipe(res);
        }
    });
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`VM Server running at http://0.0.0.0:${PORT} serving ${ROOT_DIR}`);
});
