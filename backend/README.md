# Synap Backend

Backend serverless (Vercel) do app **Synap**. Guarda as chaves de API e faz a análise
multi-modo das fotos enviadas pelo app: aparelho de academia (`equipment`),
comida (`food`) ou não identificado (`unknown`).

Endpoint único:

```
POST /api/analyze
Content-Type: application/json

{ "imageBase64": "<base64 da foto>", "mediaType": "image/jpeg" }
```

A resposta é o JSON da análise, sempre com o campo `disclaimer`. No modo `equipment`
também vêm `video` (um vídeo do YouTube com a execução) e `images` (até 4 imagens).

## Variáveis de ambiente

Copie `.env.example` para `.env` e preencha:

| Variável | Obrigatória | Descrição |
| --- | --- | --- |
| `ANTHROPIC_API_KEY` | sim | Chave da API da Anthropic |
| `MODEL` | não | Modelo usado (padrão: `claude-sonnet-4-6`) |
| `YOUTUBE_API_KEY` | não | YouTube Data API v3 — sem ela, `video` vem `null` |
| `GOOGLE_CSE_KEY` | não | Google Custom Search — sem ela, `images` vem `[]` |
| `GOOGLE_CSE_CX` | não | ID do mecanismo de busca personalizado |

## Rodar local

Requer Node 18+ (usa `fetch` global e `--env-file`). Sem dependências para instalar.

```bash
cd backend
cp .env.example .env   # preencha as chaves
npm run dev            # http://localhost:3000/api/analyze
```

## Deploy

Deploy pela Vercel apontando **Root Directory = `backend`**. Cadastre as mesmas
variáveis de ambiente no painel do projeto (Settings → Environment Variables).
