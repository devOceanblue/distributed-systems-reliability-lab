import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT_DIR = path.dirname(fileURLToPath(import.meta.url));
const FRONTEND_PORT = Number.parseInt(process.env.FRONTEND_PORT || '8088', 10);
const COMMAND_BASE_URL = stripTrailingSlash(process.env.COMMAND_BASE_URL || 'http://localhost:8080');
const QUERY_BASE_URL = stripTrailingSlash(process.env.QUERY_BASE_URL || 'http://localhost:8083');

const MIME_TYPES = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.txt': 'text/plain; charset=utf-8'
};

function stripTrailingSlash(url) {
  return url.endsWith('/') ? url.slice(0, -1) : url;
}

function hasBody(method) {
  return method === 'POST' || method === 'PUT' || method === 'PATCH' || method === 'DELETE';
}

function parseRequestPath(reqUrl) {
  const normalized = reqUrl || '/';
  return normalized.split('?')[0];
}

async function readRequestBody(req) {
  const chunks = [];
  for await (const chunk of req) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

function buildProxyTarget(urlPath, search) {
  if (urlPath.startsWith('/api/command/')) {
    const rest = urlPath.slice('/api/command'.length);
    return `${COMMAND_BASE_URL}${rest}${search}`;
  }

  if (urlPath.startsWith('/api/query/')) {
    const rest = urlPath.slice('/api/query'.length);
    return `${QUERY_BASE_URL}${rest}${search}`;
  }

  return null;
}

function normalizeHeaders(incomingHeaders) {
  const outbound = new Headers();

  Object.entries(incomingHeaders).forEach(([name, value]) => {
    if (value == null) {
      return;
    }

    const lowered = name.toLowerCase();
    if (lowered === 'host' || lowered === 'content-length' || lowered === 'connection') {
      return;
    }

    if (Array.isArray(value)) {
      outbound.set(name, value.join(','));
      return;
    }

    outbound.set(name, String(value));
  });

  return outbound;
}

async function proxyRequest(req, res, targetUrl) {
  try {
    const method = (req.method || 'GET').toUpperCase();
    const headers = normalizeHeaders(req.headers);
    const body = hasBody(method) ? await readRequestBody(req) : null;

    const upstreamResponse = await fetch(targetUrl, {
      method,
      headers,
      body: body && body.length > 0 ? body : undefined
    });

    const upstreamBody = Buffer.from(await upstreamResponse.arrayBuffer());
    const outgoingHeaders = {};

    upstreamResponse.headers.forEach((value, key) => {
      const lowered = key.toLowerCase();
      if (lowered === 'transfer-encoding' || lowered === 'connection') {
        return;
      }
      outgoingHeaders[key] = value;
    });

    res.writeHead(upstreamResponse.status, outgoingHeaders);
    res.end(upstreamBody);
  } catch (error) {
    const detail = error instanceof Error ? error.message : String(error);
    res.writeHead(502, { 'content-type': 'application/json; charset=utf-8' });
    res.end(
      JSON.stringify({
        title: 'Proxy request failed',
        detail,
        target: targetUrl
      })
    );
  }
}

function resolveStaticPath(urlPath) {
  const decoded = decodeURIComponent(urlPath);
  const candidatePath = decoded === '/' ? '/index.html' : decoded;
  const absolutePath = path.normalize(path.join(ROOT_DIR, candidatePath));

  if (!absolutePath.startsWith(ROOT_DIR)) {
    return null;
  }

  return absolutePath;
}

async function serveStatic(req, res, urlPath) {
  const resolvedPath = resolveStaticPath(urlPath);
  if (!resolvedPath) {
    res.writeHead(403, { 'content-type': 'text/plain; charset=utf-8' });
    res.end('Forbidden');
    return;
  }

  try {
    const fileStat = await stat(resolvedPath);
    if (fileStat.isDirectory()) {
      throw new Error('Directory listing is not supported');
    }

    const ext = path.extname(resolvedPath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
    const content = await readFile(resolvedPath);

    res.writeHead(200, { 'content-type': contentType });
    res.end(content);
    return;
  } catch {
    const indexPath = path.join(ROOT_DIR, 'index.html');
    const indexContent = await readFile(indexPath);
    res.writeHead(200, { 'content-type': 'text/html; charset=utf-8' });
    res.end(indexContent);
  }
}

const server = createServer(async (req, res) => {
  const method = (req.method || 'GET').toUpperCase();
  const parsed = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
  const urlPath = parseRequestPath(parsed.pathname);

  if (urlPath === '/health') {
    res.writeHead(200, { 'content-type': 'application/json; charset=utf-8' });
    res.end(
      JSON.stringify({
        status: 'UP',
        commandBaseUrl: COMMAND_BASE_URL,
        queryBaseUrl: QUERY_BASE_URL
      })
    );
    return;
  }

  const targetUrl = buildProxyTarget(urlPath, parsed.search || '');
  if (targetUrl) {
    await proxyRequest(req, res, targetUrl);
    return;
  }

  if (method !== 'GET' && method !== 'HEAD') {
    res.writeHead(405, { 'content-type': 'text/plain; charset=utf-8' });
    res.end('Method not allowed');
    return;
  }

  await serveStatic(req, res, urlPath);
});

server.listen(FRONTEND_PORT, () => {
  console.log(
    `[frontend] listening on http://localhost:${FRONTEND_PORT} (command=${COMMAND_BASE_URL}, query=${QUERY_BASE_URL})`
  );
});
