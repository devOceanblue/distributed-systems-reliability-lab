import {
  RequestIdStrategy,
  buildIntentKey,
  deriveTraceId,
  releaseStickyRequestId,
  resolveRequestId
} from './core/idempotency.mjs';
import { fetchBalance, fetchQueryMetrics, postBalanceCommand } from './core/api.mjs';
import { appendLog, appendOperation, loadState, saveState } from './core/store.mjs';

let state = loadState();

const elements = {
  commandBaseUrlInput: document.getElementById('command-base-url'),
  queryBaseUrlInput: document.getElementById('query-base-url'),
  commandTypeSelect: document.getElementById('command-type'),
  accountIdInput: document.getElementById('account-id'),
  amountInput: document.getElementById('amount'),
  strategySelect: document.getElementById('request-id-strategy'),
  manualRequestIdInput: document.getElementById('manual-request-id'),
  traceIdInput: document.getElementById('trace-id'),
  autoRefreshCheckbox: document.getElementById('auto-refresh-balance'),
  preparedRequestId: document.getElementById('prepared-request-id'),
  preparedTraceId: document.getElementById('prepared-trace-id'),
  preparedIntentKey: document.getElementById('prepared-intent-key'),
  preparedStrategy: document.getElementById('prepared-strategy'),
  sendButton: document.getElementById('send-command'),
  retryButton: document.getElementById('retry-same-request-id'),
  duplicateButton: document.getElementById('inject-duplicate'),
  prepareButton: document.getElementById('prepare-command'),
  newIntentButton: document.getElementById('new-intent'),
  saveConfigButton: document.getElementById('save-config'),
  refreshBalanceButton: document.getElementById('refresh-balance'),
  refreshMetricsButton: document.getElementById('refresh-metrics'),
  operationsBody: document.getElementById('operations-body'),
  logsBody: document.getElementById('logs-body'),
  balanceSnapshot: document.getElementById('balance-snapshot'),
  metricsSnapshot: document.getElementById('metrics-snapshot'),
  statusBanner: document.getElementById('status-banner')
};

hydrateFormFromState();
render();
bindEvents();

function bindEvents() {
  elements.strategySelect.addEventListener('change', () => {
    syncManualRequestIdInput();
  });

  elements.saveConfigButton.addEventListener('click', () => {
    mutateState((current) =>
      appendLog(
        {
          ...current,
          commandBaseUrl: readCommandBaseUrl(),
          queryBaseUrl: readQueryBaseUrl()
        },
        `API endpoint saved (command=${readCommandBaseUrl()}, query=${readQueryBaseUrl()})`
      )
    );
  });

  elements.prepareButton.addEventListener('click', () => {
    try {
      prepareCommand();
    } catch (error) {
      onUiError(error);
    }
  });

  elements.sendButton.addEventListener('click', async () => {
    elements.sendButton.disabled = true;
    try {
      const prepared = prepareCommand();
      await executeCommand(prepared, 'send');
      await maybeRefreshBalance(prepared.accountId);
    } catch (error) {
      onUiError(error);
    } finally {
      elements.sendButton.disabled = false;
    }
  });

  elements.retryButton.addEventListener('click', async () => {
    const prepared = state.lastPreparedCommand;
    if (!prepared) {
      setStatus('Retry target is empty. Prepare a command first.', 'warn');
      return;
    }

    elements.retryButton.disabled = true;
    try {
      await executeCommand(prepared, 'retry-same-request-id');
      await maybeRefreshBalance(prepared.accountId);
    } catch (error) {
      onUiError(error);
    } finally {
      elements.retryButton.disabled = false;
    }
  });

  elements.duplicateButton.addEventListener('click', async () => {
    elements.duplicateButton.disabled = true;
    try {
      const prepared = prepareCommand();
      await Promise.all([
        executeCommand(prepared, 'duplicate-1'),
        executeCommand(prepared, 'duplicate-2')
      ]);
      await maybeRefreshBalance(prepared.accountId);
    } catch (error) {
      onUiError(error);
    } finally {
      elements.duplicateButton.disabled = false;
    }
  });

  elements.newIntentButton.addEventListener('click', () => {
    try {
      const input = readCommandInput();
      const intentKey = buildIntentKey(input);
      mutateState((current) => {
        const nextStickyRequestIds = releaseStickyRequestId(current.stickyRequestIds, intentKey);
        return appendLog(
          {
            ...current,
            stickyRequestIds: nextStickyRequestIds,
            lastPreparedCommand: null
          },
          `Sticky request-id released for intent ${intentKey}`
        );
      });
      setStatus('New intent started. Next send uses a new request-id.', 'ok');
    } catch (error) {
      onUiError(error);
    }
  });

  elements.refreshBalanceButton.addEventListener('click', async () => {
    elements.refreshBalanceButton.disabled = true;
    try {
      const { accountId } = readCommandInput();
      await refreshBalance(accountId);
    } catch (error) {
      onUiError(error);
    } finally {
      elements.refreshBalanceButton.disabled = false;
    }
  });

  elements.refreshMetricsButton.addEventListener('click', async () => {
    elements.refreshMetricsButton.disabled = true;
    try {
      await refreshMetrics();
    } catch (error) {
      onUiError(error);
    } finally {
      elements.refreshMetricsButton.disabled = false;
    }
  });
}

function readCommandBaseUrl() {
  return String(elements.commandBaseUrlInput.value || '').trim() || '/api/command';
}

function readQueryBaseUrl() {
  return String(elements.queryBaseUrlInput.value || '').trim() || '/api/query';
}

function readCommandInput() {
  return {
    accountId: String(elements.accountIdInput.value || '').trim(),
    commandType: String(elements.commandTypeSelect.value || '').toLowerCase(),
    amount: Number.parseInt(String(elements.amountInput.value || '').trim(), 10)
  };
}

function readStrategy() {
  return String(elements.strategySelect.value || RequestIdStrategy.STICKY);
}

function readManualRequestId() {
  return String(elements.manualRequestIdInput.value || '').trim();
}

function readTraceId() {
  return String(elements.traceIdInput.value || '').trim();
}

function prepareCommand() {
  const commandInput = readCommandInput();
  const strategy = readStrategy();
  const intentKey = buildIntentKey(commandInput);

  const resolvedRequestId = resolveRequestId({
    strategy,
    intentKey,
    stickyRequestIds: state.stickyRequestIds,
    manualRequestId: readManualRequestId()
  });

  const traceId = deriveTraceId(resolvedRequestId.requestId, readTraceId());

  const prepared = {
    ...commandInput,
    intentKey,
    strategy,
    requestId: resolvedRequestId.requestId,
    traceId,
    reusedRequestId: resolvedRequestId.reused,
    preparedAt: new Date().toISOString()
  };

  mutateState((current) =>
    appendLog(
      {
        ...current,
        commandBaseUrl: readCommandBaseUrl(),
        queryBaseUrl: readQueryBaseUrl(),
        stickyRequestIds: resolvedRequestId.nextStickyRequestIds,
        lastPreparedCommand: prepared
      },
      `Prepared command ${prepared.commandType} ${prepared.accountId} amount=${prepared.amount} request-id=${prepared.requestId}`
    )
  );

  setStatus(
    prepared.reusedRequestId
      ? `Prepared with reused request-id (${prepared.requestId})`
      : `Prepared with new request-id (${prepared.requestId})`,
    'ok'
  );

  return prepared;
}

async function executeCommand(prepared, source) {
  const result = await postBalanceCommand({
    commandBaseUrl: readCommandBaseUrl(),
    accountId: prepared.accountId,
    commandType: prepared.commandType,
    amount: prepared.amount,
    requestId: prepared.requestId,
    traceId: prepared.traceId
  });

  const operation = {
    source,
    requestedAt: new Date().toISOString(),
    accountId: prepared.accountId,
    commandType: prepared.commandType,
    amount: prepared.amount,
    requestId: prepared.requestId,
    traceId: prepared.traceId,
    status: result.ok ? 'OK' : 'ERROR',
    httpStatus: result.status,
    deduplicated: result.status === 409,
    response: result.ok ? result.body : result.error
  };

  if (result.ok) {
    mutateState((current) => appendOperation(appendLog(current, `Command accepted: request-id=${prepared.requestId}`), operation));
    setStatus(`Command accepted (${source})`, 'ok');
    return;
  }

  const warningMessage =
    result.status === 409
      ? `Deduplicated duplicate request (${prepared.requestId})`
      : `Command failed (${result.status}) request-id=${prepared.requestId}`;

  mutateState((current) =>
    appendOperation(
      appendLog(current, warningMessage, result.status === 409 ? 'WARN' : 'ERROR'),
      operation
    )
  );

  setStatus(warningMessage, result.status === 409 ? 'warn' : 'error');
}

async function maybeRefreshBalance(accountId) {
  if (!elements.autoRefreshCheckbox.checked) {
    return;
  }
  await refreshBalance(accountId);
}

async function refreshBalance(accountId) {
  const result = await fetchBalance({
    queryBaseUrl: readQueryBaseUrl(),
    accountId
  });

  if (!result.ok) {
    mutateState((current) => appendLog(current, `Balance query failed (${result.status})`, 'ERROR'));
    setStatus(`Balance query failed (${result.status})`, 'error');
    return;
  }

  mutateState((current) => ({
    ...appendLog(current, `Balance refreshed account=${accountId} balance=${result.body?.balance}`),
    latestBalance: result.body
  }));
  setStatus(`Balance refreshed for ${accountId}`, 'ok');
}

async function refreshMetrics() {
  const result = await fetchQueryMetrics({
    queryBaseUrl: readQueryBaseUrl()
  });

  if (!result.ok) {
    mutateState((current) => appendLog(current, `Metrics query failed (${result.status})`, 'ERROR'));
    setStatus(`Metrics query failed (${result.status})`, 'error');
    return;
  }

  mutateState((current) => ({
    ...appendLog(current, 'Query metrics refreshed'),
    latestMetrics: result.body
  }));
  setStatus('Query metrics refreshed', 'ok');
}

function onUiError(error) {
  const message = error instanceof Error ? error.message : String(error);
  mutateState((current) => appendLog(current, message, 'ERROR'));
  setStatus(message, 'error');
}

function mutateState(mutator) {
  state = mutator(state);
  saveState(state);
  render();
}

function hydrateFormFromState() {
  elements.commandBaseUrlInput.value = state.commandBaseUrl || '/api/command';
  elements.queryBaseUrlInput.value = state.queryBaseUrl || '/api/query';
  elements.commandTypeSelect.value = 'deposit';
  elements.accountIdInput.value = 'A-1';
  elements.amountInput.value = '100';
  elements.strategySelect.value = RequestIdStrategy.STICKY;
  elements.manualRequestIdInput.value = '';
  elements.traceIdInput.value = '';
  elements.autoRefreshCheckbox.checked = true;
  syncManualRequestIdInput();
}

function render() {
  renderPrepared();
  renderOperations();
  renderLogs();
  renderSnapshots();
  syncManualRequestIdInput();
}

function renderPrepared() {
  const prepared = state.lastPreparedCommand;

  if (!prepared) {
    elements.preparedRequestId.textContent = '-';
    elements.preparedTraceId.textContent = '-';
    elements.preparedIntentKey.textContent = '-';
    elements.preparedStrategy.textContent = '-';
    return;
  }

  elements.preparedRequestId.textContent = prepared.requestId;
  elements.preparedTraceId.textContent = prepared.traceId;
  elements.preparedIntentKey.textContent = prepared.intentKey;
  elements.preparedStrategy.textContent = prepared.strategy;
}

function renderOperations() {
  const rows = (state.operations || []).map((operation) => {
    const responseSummary = operation.deduplicated
      ? 'duplicate blocked (409)'
      : operation.status === 'OK'
        ? `balance=${operation.response?.balance ?? '-'}`
        : `${operation.response?.title || 'error'}: ${operation.response?.detail || ''}`;

    return `
      <tr>
        <td>${escapeHtml(operation.requestedAt || '-')}</td>
        <td>${escapeHtml(operation.source || '-')}</td>
        <td>${escapeHtml(operation.commandType || '-')}</td>
        <td>${escapeHtml(operation.accountId || '-')}</td>
        <td>${escapeHtml(String(operation.amount ?? '-'))}</td>
        <td><code>${escapeHtml(operation.requestId || '-')}</code></td>
        <td>${escapeHtml(String(operation.httpStatus ?? '-'))}</td>
        <td class="status-${operation.status === 'OK' ? 'ok' : operation.deduplicated ? 'warn' : 'error'}">${escapeHtml(
      responseSummary
    )}</td>
      </tr>
    `;
  });

  elements.operationsBody.innerHTML = rows.join('');
}

function renderLogs() {
  const rows = (state.logs || []).map((line) => {
    return `
      <tr>
        <td>${escapeHtml(line.at || '-')}</td>
        <td class="level-${String(line.level || 'INFO').toLowerCase()}">${escapeHtml(line.level || 'INFO')}</td>
        <td>${escapeHtml(line.message || '-')}</td>
      </tr>
    `;
  });

  elements.logsBody.innerHTML = rows.join('');
}

function renderSnapshots() {
  elements.balanceSnapshot.textContent = state.latestBalance
    ? JSON.stringify(state.latestBalance, null, 2)
    : '{\n  "message": "balance snapshot is empty"\n}';

  elements.metricsSnapshot.textContent = state.latestMetrics
    ? JSON.stringify(state.latestMetrics, null, 2)
    : '{\n  "message": "metrics snapshot is empty"\n}';
}

function syncManualRequestIdInput() {
  const strategy = readStrategy();
  const manualMode = strategy === RequestIdStrategy.MANUAL;
  elements.manualRequestIdInput.disabled = !manualMode;
  elements.manualRequestIdInput.required = manualMode;
}

function setStatus(message, level) {
  elements.statusBanner.textContent = message;
  elements.statusBanner.dataset.level = level;
}

function escapeHtml(rawValue) {
  return String(rawValue)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}
