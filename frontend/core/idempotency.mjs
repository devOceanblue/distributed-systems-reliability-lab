const REQUEST_ID_PATTERN = /^[a-zA-Z0-9:_-]{1,64}$/;

export const RequestIdStrategy = Object.freeze({
  STICKY: 'STICKY',
  ALWAYS_NEW: 'ALWAYS_NEW',
  MANUAL: 'MANUAL'
});

export function buildIntentKey({ accountId, commandType, amount }) {
  const normalizedAccountId = String(accountId || '').trim();
  const normalizedType = normalizeCommandType(commandType);
  const normalizedAmount = Number.parseInt(String(amount), 10);

  if (!normalizedAccountId) {
    throw new Error('accountId is required');
  }

  if (!Number.isFinite(normalizedAmount) || normalizedAmount <= 0) {
    throw new Error('amount must be a positive integer');
  }

  return `${normalizedType}:${normalizedAccountId}:${normalizedAmount}`;
}

export function normalizeCommandType(commandType) {
  const candidate = String(commandType || '').toLowerCase();
  if (candidate !== 'deposit' && candidate !== 'withdraw') {
    throw new Error(`unsupported commandType: ${commandType}`);
  }
  return candidate;
}

export function sanitizeRequestId(rawValue) {
  const value = String(rawValue || '').trim();
  if (!REQUEST_ID_PATTERN.test(value)) {
    throw new Error('request-id must match /^[a-zA-Z0-9:_-]{1,64}$/');
  }
  return value;
}

export function deriveTraceId(requestId, customTraceId) {
  const candidate = String(customTraceId || '').trim();
  if (candidate) {
    return candidate;
  }
  return `trace-${requestId}`;
}

export function resolveRequestId({
  strategy,
  intentKey,
  stickyRequestIds,
  manualRequestId,
  generateId
}) {
  const nextStickyRequestIds = { ...(stickyRequestIds || {}) };
  const generator = typeof generateId === 'function' ? generateId : defaultRequestIdGenerator;

  if (strategy === RequestIdStrategy.ALWAYS_NEW) {
    return {
      requestId: sanitizeRequestId(generator()),
      reused: false,
      nextStickyRequestIds
    };
  }

  if (strategy === RequestIdStrategy.MANUAL) {
    return {
      requestId: sanitizeRequestId(manualRequestId),
      reused: false,
      nextStickyRequestIds
    };
  }

  if (strategy !== RequestIdStrategy.STICKY) {
    throw new Error(`unsupported request-id strategy: ${strategy}`);
  }

  const existing = nextStickyRequestIds[intentKey];
  if (existing) {
    return {
      requestId: sanitizeRequestId(existing),
      reused: true,
      nextStickyRequestIds
    };
  }

  const generatedRequestId = sanitizeRequestId(generator());
  nextStickyRequestIds[intentKey] = generatedRequestId;

  return {
    requestId: generatedRequestId,
    reused: false,
    nextStickyRequestIds
  };
}

export function releaseStickyRequestId(stickyRequestIds, intentKey) {
  const next = { ...(stickyRequestIds || {}) };
  delete next[intentKey];
  return next;
}

export function defaultRequestIdGenerator() {
  if (globalThis.crypto && typeof globalThis.crypto.randomUUID === 'function') {
    return `req-${globalThis.crypto.randomUUID()}`;
  }

  const suffix = Math.random().toString(16).slice(2, 14);
  const timestamp = Date.now().toString(16);
  return `req-${timestamp}-${suffix}`;
}
