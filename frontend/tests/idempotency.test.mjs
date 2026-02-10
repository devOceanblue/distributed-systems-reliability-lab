import test from 'node:test';
import assert from 'node:assert/strict';

import {
  RequestIdStrategy,
  buildIntentKey,
  deriveTraceId,
  releaseStickyRequestId,
  resolveRequestId,
  sanitizeRequestId
} from '../core/idempotency.mjs';

test('buildIntentKey normalizes fields', () => {
  const key = buildIntentKey({ accountId: 'A-1', commandType: 'deposit', amount: 100 });
  assert.equal(key, 'deposit:A-1:100');
});

test('resolveRequestId STICKY reuses existing id', () => {
  const first = resolveRequestId({
    strategy: RequestIdStrategy.STICKY,
    intentKey: 'deposit:A-1:100',
    stickyRequestIds: {},
    generateId: () => 'req-fixed-1'
  });

  assert.equal(first.requestId, 'req-fixed-1');
  assert.equal(first.reused, false);

  const second = resolveRequestId({
    strategy: RequestIdStrategy.STICKY,
    intentKey: 'deposit:A-1:100',
    stickyRequestIds: first.nextStickyRequestIds,
    generateId: () => 'req-fixed-2'
  });

  assert.equal(second.requestId, 'req-fixed-1');
  assert.equal(second.reused, true);
});

test('resolveRequestId ALWAYS_NEW always generates a new request-id', () => {
  const first = resolveRequestId({
    strategy: RequestIdStrategy.ALWAYS_NEW,
    intentKey: 'deposit:A-1:100',
    stickyRequestIds: {},
    generateId: () => 'req-new-1'
  });

  const second = resolveRequestId({
    strategy: RequestIdStrategy.ALWAYS_NEW,
    intentKey: 'deposit:A-1:100',
    stickyRequestIds: first.nextStickyRequestIds,
    generateId: () => 'req-new-2'
  });

  assert.equal(first.requestId, 'req-new-1');
  assert.equal(second.requestId, 'req-new-2');
});

test('resolveRequestId MANUAL validates format', () => {
  const resolved = resolveRequestId({
    strategy: RequestIdStrategy.MANUAL,
    intentKey: 'deposit:A-1:100',
    stickyRequestIds: {},
    manualRequestId: 'req-manual-1'
  });

  assert.equal(resolved.requestId, 'req-manual-1');

  assert.throws(
    () =>
      resolveRequestId({
        strategy: RequestIdStrategy.MANUAL,
        intentKey: 'deposit:A-1:100',
        stickyRequestIds: {},
        manualRequestId: 'req manual with space'
      }),
    /request-id/
  );
});

test('releaseStickyRequestId removes one intent key only', () => {
  const next = releaseStickyRequestId(
    {
      'deposit:A-1:100': 'req-a',
      'withdraw:A-1:50': 'req-b'
    },
    'deposit:A-1:100'
  );

  assert.deepEqual(next, {
    'withdraw:A-1:50': 'req-b'
  });
});

test('deriveTraceId falls back to request-id derived value', () => {
  assert.equal(deriveTraceId('req-1', ''), 'trace-req-1');
  assert.equal(deriveTraceId('req-1', 'custom-trace'), 'custom-trace');
});

test('sanitizeRequestId enforces length and allowed characters', () => {
  assert.equal(sanitizeRequestId('req_1:abc-xyz'), 'req_1:abc-xyz');
  assert.throws(() => sanitizeRequestId(''), /request-id/);
  assert.throws(() => sanitizeRequestId('bad$id'), /request-id/);
});
