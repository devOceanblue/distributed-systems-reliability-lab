package com.reliabilitylab.commandservice.api;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;

public record BalanceCommandRequest(
        @NotBlank String txId,
        @Positive long amount,
        String traceId
) {
}
