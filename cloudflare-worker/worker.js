/**
 * ChemiCheck — Claude API 프록시 (Cloudflare Workers)
 *
 * 배포 방법:
 * 1. cloudflare.com → Workers & Pages → Create Application → Create Worker
 * 2. 이 파일의 코드를 전체 붙여넣기 → Deploy
 * 3. Settings → Variables → Secrets → Add Secret
 *    Name: ANTHROPIC_API_KEY   Value: sk-ant-... (Claude API 키)
 * 4. Worker URL (https://chemicheck-proxy.xxx.workers.dev) 복사
 *    → Xcode 스킴 환경변수 PROXY_BASE_URL 에 붙여넣기
 */

export default {
  async fetch(request, env) {

    // CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        },
      });
    }

    // /api/chat 경로만 허용
    const url = new URL(request.url);
    if (url.pathname !== '/api/chat') {
      return new Response('Not Found', { status: 404 });
    }

    if (request.method !== 'POST') {
      return new Response('Method Not Allowed', { status: 405 });
    }

    // API 키 확인
    if (!env.ANTHROPIC_API_KEY) {
      return new Response(
        JSON.stringify({ error: 'ANTHROPIC_API_KEY not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      );
    }

    let body;
    try {
      body = await request.json();
    } catch {
      return new Response(
        JSON.stringify({ error: 'Invalid JSON body' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      );
    }

    // Anthropic API 호출
    const anthropicResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'x-api-key': env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    const data = await anthropicResponse.json();

    return new Response(JSON.stringify(data), {
      status: anthropicResponse.status,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  },
};
