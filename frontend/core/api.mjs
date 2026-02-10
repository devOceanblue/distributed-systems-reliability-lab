import { normalizeCommandType } from './idempotency.mjs';

function trimTrailingSlash(url) {
  const value = String(url || '').trim();
  return value.endsWith('/') ? value.slice(0, -1) : value;
}

function parseMaybeJson(rawText) {
  if (!rawText) {
    return null;
  }

  try {
    return JSON.parse(rawText);
  } catch {
    return { rawText };
  }
}

async function decodeResponse(response) {
  const rawText = await response.text();
  const decodedBody = parseMaybeJson(rawText);

  if (response.ok) {
    return {
      ok: true,
      status: response.status,
      body: decodedBody
    };
  }

  const title = decodedBody?.title || `HTTP ${response.status}`;
  const detail = decodedBody?.detail || decodedBody?.rawText || 'request failed';

  return {
    ok: false,
    status: response.status,
    error: {
      title,
      detail,
      body: decodedBody
    }
  };
}

export function createCommandHttpRequest({
  commandBaseUrl,
  accountId,
  commandType,
  amount,
  requestId,
  traceId
}) {
  const normalizedBaseUrl = trimTrailingSlash(commandBaseUrl);
  const normalizedCommandType = normalizeCommandType(commandType);
  const normalizedAmount = Number.parseInt(String(amount), 10);

  if (!normalizedBaseUrl) {
    throw new Error('commandBaseUrl is required');
  }

  if (!accountId || !String(accountId).trim()) {
    throw new Error('accountId is required');
  }

  if (!Number.isFinite(normalizedAmount) || normalizedAmount <= 0) {
    throw new Error('amount must be a positive integer');
  }

  const path = `/accounts/${encodeURIComponent(String(accountId).trim())}/${normalizedCommandType}`;
  const url = `${normalizedBaseUrl}${path}`;

  return {
    url,
    init: {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-request-id': requestId,
        'x-trace-id': traceId,
        'idempotency-key': requestId
      },
      body: JSON.stringify({
        txId: requestId,
        amount: normalizedAmount,
        traceId
      })
    }
  };
}

export async function postBalanceCommand({
  fetchImpl = fetch,
  commandBaseUrl,
  accountId,
  commandType,
  amount,
  requestId,
  traceId
}) {
  const request = createCommandHttpRequest({
    commandBaseUrl,
    accountId,
    commandType,
    amount,
    requestId,
    traceId
  });

  const response = await fetchImpl(request.url, request.init);
  const decoded = await decodeResponse(response);

  return {
    ...decoded,
    request
  };
}

export async function fetchBalance({ fetchImpl = fetch, queryBaseUrl, accountId }) {
  const normalizedBaseUrl = trimTrailingSlash(queryBaseUrl);
  const targetUrl = `${normalizedBaseUrl}/accounts/${encodeURIComponent(String(accountId).trim())}/balance`;

  const response = await fetchImpl(targetUrl, {
    method: 'GET',
    headers: {
      accept: 'application/json'
    }
  });

  const decoded = await decodeResponse(response);
  return {
    ...decoded,
    url: targetUrl
  };
}

export async function fetchQueryMetrics({ fetchImpl = fetch, queryBaseUrl }) {
  const normalizedBaseUrl = trimTrailingSlash(queryBaseUrl);
  const targetUrl = `${normalizedBaseUrl}/internal/query/metrics`;

  const response = await fetchImpl(targetUrl, {
    method: 'GET',
    headers: {
      accept: 'application/json'
    }
  });

  const decoded = await decodeResponse(response);
  return {
    ...decoded,
    url: targetUrl
  };
}
