// Servidor local apenas para testes (o deploy real usa as funções serverless da Vercel).
import http from 'node:http';
import handler from './api/analyze.js';

const PORT = 3000;

function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (chunk) => {
      raw += chunk;
    });
    req.on('end', () => resolve(raw));
    req.on('error', reject);
  });
}

function adaptRes(res) {
  res.status = (code) => {
    res.statusCode = code;
    return res;
  };
  res.json = (payload) => {
    const body = JSON.stringify(payload);
    res.setHeader('content-type', 'application/json; charset=utf-8');
    res.end(body);
    return res;
  };
  return res;
}

const server = http.createServer(async (req, res) => {
  adaptRes(res);

  const { pathname } = new URL(req.url, `http://localhost:${PORT}`);

  if (pathname !== '/api/analyze') {
    res.status(404).json({ error: 'Rota não encontrada.' });
    return;
  }

  if (req.method !== 'POST' && req.method !== 'OPTIONS') {
    res.status(405).json({ error: 'Método não permitido. Use POST.' });
    return;
  }

  try {
    const raw = req.method === 'POST' ? await readBody(req) : '';
    req.body = raw ? JSON.parse(raw) : {};
  } catch {
    res.status(400).json({ error: 'JSON inválido no corpo da requisição.' });
    return;
  }

  try {
    await handler(req, res);
  } catch (err) {
    console.error(err);
    if (!res.writableEnded) {
      res.status(500).json({ error: `Erro interno: ${err?.message ?? err}` });
    }
  }
});

server.listen(PORT, () => {
  console.log(`Synap backend (dev) rodando em http://localhost:${PORT}/api/analyze`);
});
