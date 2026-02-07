package com.reliabilitylab.outboxrelay.api;

import com.reliabilitylab.outboxrelay.app.OutboxRelayService;
import com.reliabilitylab.outboxrelay.app.RelayRunResult;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/internal/relay")
public class RelayController {
    private final OutboxRelayService outboxRelayService;

    public RelayController(OutboxRelayService outboxRelayService) {
        this.outboxRelayService = outboxRelayService;
    }

    @PostMapping("/run-once")
    public RelayRunResponse runOnce() {
        RelayRunResult result = outboxRelayService.runOnce();
        return new RelayRunResponse(result.processed(), result.state(), result.outboxId(), result.dedupKey());
    }
}
