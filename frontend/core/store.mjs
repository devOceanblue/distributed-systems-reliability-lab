const STORAGE_KEY = 'reliability_lab_frontend_v1';

const DEFAULT_STATE = Object.freeze({
  commandBaseUrl: '/api/command',
  queryBaseUrl: '/api/query',
  stickyRequestIds: {},
  operations: [],
  logs: [],
  lastPreparedCommand: null,
  latestBalance: null,
  latestMetrics: null
});

export function defaultState() {
  return {
    commandBaseUrl: DEFAULT_STATE.commandBaseUrl,
    queryBaseUrl: DEFAULT_STATE.queryBaseUrl,
    stickyRequestIds: {},
    operations: [],
    logs: [],
    lastPreparedCommand: null,
    latestBalance: null,
    latestMetrics: null
  };
}

export function loadState(storage = globalThis.localStorage) {
  if (!storage) {
    return defaultState();
  }

  const raw = storage.getItem(STORAGE_KEY);
  if (!raw) {
    return defaultState();
  }

  try {
    const parsed = JSON.parse(raw);
    return {
      ...defaultState(),
      ...parsed,
      stickyRequestIds: { ...(parsed?.stickyRequestIds || {}) },
      operations: Array.isArray(parsed?.operations) ? parsed.operations.slice(0, 50) : [],
      logs: Array.isArray(parsed?.logs) ? parsed.logs.slice(0, 80) : []
    };
  } catch {
    return defaultState();
  }
}

export function saveState(state, storage = globalThis.localStorage) {
  if (!storage) {
    return;
  }

  storage.setItem(STORAGE_KEY, JSON.stringify(state));
}

export function appendOperation(state, operation) {
  const operations = [operation, ...(state.operations || [])].slice(0, 30);
  return {
    ...state,
    operations
  };
}

export function appendLog(state, message, level = 'INFO') {
  const now = new Date();
  const line = {
    at: now.toISOString(),
    message,
    level
  };

  const logs = [line, ...(state.logs || [])].slice(0, 80);
  return {
    ...state,
    logs
  };
}
