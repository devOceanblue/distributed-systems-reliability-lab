package com.reliabilitylab.commandservice.app;

import com.reliabilitylab.eventcore.EventEnvelope;

public record CommandTxResult(long balance, EventEnvelope envelope) {
}
