const ANTHROPIC_URL = 'https://api.anthropic.com/v1/messages';
const YOUTUBE_URL = 'https://www.googleapis.com/youtube/v3/search';
const CSE_URL = 'https://www.googleapis.com/customsearch/v1';

const MAX_IMAGE_CHARS = 4_000_000;

const DISCLAIMER =
  '⚠️ O Synap é um assistente de dicas educativas. Ele não substitui o acompanhamento de um personal trainer nem de um(a) nutricionista — esses profissionais são prioridade para treinos e alimentação seguros e personalizados.';

const INSTRUCTION = `Você é o Synap, assistente de academia e alimentação. Analise a imagem e classifique em um dos modos: 'equipment' (aparelho/equipamento de academia), 'food' (comida/bebida/prato) ou 'unknown'. Responda APENAS com JSON válido, sem markdown.

Formatos aceitos:

- equipment:
{
  "mode": "equipment",
  "name": "nome do aparelho",
  "primaryMuscle": "músculo principal trabalhado",
  "secondaryMuscles": ["músculos secundários"],
  "description": "1-2 frases amigáveis",
  "steps": ["4 a 5 passos curtos de execução"],
  "youtubeQuery": "busca no youtube para ver a execução em português",
  "imagesQuery": "busca no google imagens da execução e músculos"
}

- food:
{
  "mode": "food",
  "foodName": "nome do prato/alimento",
  "healthScore": 7,
  "caloriesEstimate": "faixa aproximada por porção, ex: 250–300 kcal",
  "pros": ["pontos positivos"],
  "cons": ["pontos de atenção"],
  "healthierSwap": "uma troca mais saudável",
  "tip": "uma dica educativa curta"
}
O campo healthScore é um número de 1 a 10.

- unknown:
{
  "mode": "unknown",
  "message": "mensagem simpática pedindo foto de um aparelho de academia ou de uma comida"
}

Use sempre um tom amigável brasileiro. Dê apenas dicas educativas gerais: nunca prescreva dieta ou plano fechado.`;

function setCors(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

function extractJson(raw) {
  let text = String(raw || '').trim();
  // remove cercas de código (```json ... ```)
  text = text.replace(/^```[a-zA-Z]*\s*/, '').replace(/```\s*$/, '');
  const start = text.indexOf('{');
  const end = text.lastIndexOf('}');
  if (start === -1 || end === -1 || end < start) return null;
  return text.slice(start, end + 1);
}

async function searchYoutube(query) {
  const key = process.env.YOUTUBE_API_KEY;
  if (!key || !query) return null;
  try {
    const url = new URL(YOUTUBE_URL);
    url.searchParams.set('part', 'snippet');
    url.searchParams.set('type', 'video');
    url.searchParams.set('videoEmbeddable', 'true');
    url.searchParams.set('maxResults', '1');
    url.searchParams.set('q', query);
    url.searchParams.set('key', key);

    const r = await fetch(url);
    if (!r.ok) return null;
    const data = await r.json();
    const item = data?.items?.[0];
    const videoId = item?.id?.videoId;
    if (!videoId) return null;
    return { videoId, title: item?.snippet?.title ?? '' };
  } catch {
    return null;
  }
}

async function searchImages(query) {
  const key = process.env.GOOGLE_CSE_KEY;
  const cx = process.env.GOOGLE_CSE_CX;
  if (!key || !cx || !query) return [];
  try {
    const url = new URL(CSE_URL);
    url.searchParams.set('key', key);
    url.searchParams.set('cx', cx);
    url.searchParams.set('searchType', 'image');
    url.searchParams.set('num', '4');
    url.searchParams.set('q', query);

    const r = await fetch(url);
    if (!r.ok) return [];
    const data = await r.json();
    const items = Array.isArray(data?.items) ? data.items : [];
    return items
      .map((it) => ({ thumb: it?.image?.thumbnailLink ?? null, full: it?.link ?? null }))
      .filter((img) => img.thumb || img.full);
  } catch {
    return [];
  }
}

export default async function handler(req, res) {
  setCors(res);

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }

  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Método não permitido. Use POST.' });
    return;
  }

  let body = req.body;
  if (typeof body === 'string') {
    try {
      body = JSON.parse(body);
    } catch {
      res.status(400).json({ error: 'JSON inválido no corpo da requisição.' });
      return;
    }
  }

  const imageBase64 = body?.imageBase64;
  const mediaType = body?.mediaType;

  if (!imageBase64 || !mediaType) {
    res.status(400).json({ error: 'Campos obrigatórios: imageBase64 e mediaType.' });
    return;
  }

  if (imageBase64.length > MAX_IMAGE_CHARS) {
    res.status(413).json({ error: 'Imagem muito grande. Envie uma foto menor.' });
    return;
  }

  if (!process.env.ANTHROPIC_API_KEY) {
    res.status(500).json({ error: 'ANTHROPIC_API_KEY não configurada no servidor.' });
    return;
  }

  let anthropicResponse;
  try {
    anthropicResponse = await fetch(ANTHROPIC_URL, {
      method: 'POST',
      headers: {
        'x-api-key': process.env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        model: process.env.MODEL || 'claude-sonnet-4-6',
        max_tokens: 1200,
        messages: [
          {
            role: 'user',
            content: [
              {
                type: 'image',
                source: {
                  type: 'base64',
                  media_type: mediaType,
                  data: imageBase64,
                },
              },
              { type: 'text', text: INSTRUCTION },
            ],
          },
        ],
      }),
    });
  } catch (err) {
    res.status(502).json({ error: `Falha ao contatar a API da Anthropic: ${err?.message ?? err}` });
    return;
  }

  if (!anthropicResponse.ok) {
    let message = `Erro ${anthropicResponse.status} na API da Anthropic.`;
    try {
      const errBody = await anthropicResponse.json();
      const detail = errBody?.error?.message;
      if (detail) message = detail;
    } catch {
      // mantém a mensagem padrão
    }
    res.status(anthropicResponse.status).json({ error: message });
    return;
  }

  const data = await anthropicResponse.json();
  const rawText = (Array.isArray(data?.content) ? data.content : [])
    .filter((block) => block?.type === 'text')
    .map((block) => block.text)
    .join('\n');

  const jsonSlice = extractJson(rawText);
  let result;
  try {
    if (!jsonSlice) throw new Error('nenhum JSON encontrado na resposta');
    result = JSON.parse(jsonSlice);
  } catch (err) {
    res.status(500).json({
      error: `Não consegui interpretar a resposta do modelo (${err?.message ?? err}). Tente novamente.`,
    });
    return;
  }

  if (result?.mode === 'equipment') {
    const [video, images] = await Promise.all([
      searchYoutube(result.youtubeQuery),
      searchImages(result.imagesQuery),
    ]);
    result.video = video;
    result.images = images;
  }

  result.disclaimer = DISCLAIMER;

  res.status(200).json(result);
}
