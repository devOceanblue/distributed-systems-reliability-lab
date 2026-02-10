import test from 'node:test';
import assert from 'node:assert/strict';

import {
  createCommandHttpRequest,
  fetchBalance,
  fetchQueryMetrics,
  postBalanceCommand
} from '../core/api.mjs';

test('createCommandHttpRequest builds URL, headers and payload with request-id', () => {
  const request = createCommandHttpRequest({
    commandBaseUrl: '/api/command',
    accountId: 'A-1',
    commandType: 'deposit',
    amount: 100,
    requestId: 'req-abc-1',
    traceId: 'trace-abc-1'
  });

  assert.equal(request.url, '/api/command/accounts/A-1/deposit');
  assert.equal(request.init.method, 'POST');
  assert.equal(request.init.headers['x-request-id'], 'req-abc-1');
  assert.equal(request.init.headers['idempotency-key'], 'req-abc-1');

  const body = JSON.parse(request.init.body);
  assert.deepEqual(body, {
    txId: 'req-abc-1',
    amount: 100,
    traceId: 'trace-abc-1'
  });
});

test('postBalanceCommand decodes successful JSON response', async () => {
  const fetchImpl = async () => {
    return new Response(
      JSON.stringify({ status: 'OK', balance: 100 }),
      {
        status: 200,
        headers: {
          'content-type': 'application/json'
        }
      }
    );
  };

  const result = await postBalanceCommand({
    fetchImpl,
    commandBaseUrl: '/api/command',
    accountId: 'A-1',
    commandType: 'deposit',
    amount: 100,
    requestId: 'req-1',
    traceId: 'trace-1'
  });

  assert.equal(result.ok, true);
  assert.equal(result.status, 200);
  assert.equal(result.body.balance, 100);
});

test('postBalanceCommand decodes 409 conflict response', async () => {
  const fetchImpl = async () => {
    return new Response(
      JSON.stringify({
        title: 'Data integrity violation',
        detail: 'Duplicate entry req-1 for key ledger.PRIMARY'
      }),
      {
        status: 409,
        headers: {
          'content-type': 'application/json'
        }
      }
    );
  };

  const result = await postBalanceCommand({
    fetchImpl,
    commandBaseUrl: '/api/command',
    accountId: 'A-1',
    commandType: 'deposit',
    amount: 100,
    requestId: 'req-1',
    traceId: 'trace-1'
  });

  assert.equal(result.ok, false);
  assert.equal(result.status, 409);
  assert.match(result.error.detail, /Duplicate entry/);
});

test('fetchBalance and fetchQueryMetrics parse query responses', async () => {
  const fetchImpl = async (url) => {
    if (url.endsWith('/balance')) {
      return new Response(JSON.stringify({ accountId: 'A-1', balance: 500 }), { status: 200 });
    }

    return new Response(JSON.stringify({ cacheHit: 2, cacheMiss: 1, dbRead: 1 }), { status: 200 });
  };

  const balance = await fetchBalance({ fetchImpl, queryBaseUrl: '/api/query', accountId: 'A-1' });
  const metrics = await fetchQueryMetrics({ fetchImpl, queryBaseUrl: '/api/query' });

  assert.equal(balance.ok, true);
  assert.equal(balance.body.balance, 500);
  assert.equal(metrics.ok, true);
  assert.equal(metrics.body.cacheHit, 2);
});
