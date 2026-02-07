package com.reliabilitylab.replayworker.api;

import com.reliabilitylab.replayworker.app.CapturedDlqEvent;
import com.reliabilitylab.replayworker.app.ReplayRunCommand;
import com.reliabilitylab.replayworker.app.ReplayRunResult;
import com.reliabilitylab.replayworker.app.ReplayWorkerService;
import com.reliabilitylab.replayworker.config.ReplayWorkerProperties;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Locale;

@RestController
@RequestMapping("/internal/replay")
public class ReplayController {
    private final ReplayWorkerService replayWorkerService;
    private final ReplayWorkerProperties properties;

    public ReplayController(ReplayWorkerService replayWorkerService,
                            ReplayWorkerProperties properties) {
        this.replayWorkerService = replayWorkerService;
        this.properties = properties;
    }

    @PostMapping("/ingest")
    public ReplayIngestResponse ingest(@RequestBody @Valid ReplayIngestRequest request) {
        String eventId = request.eventId();
        if (eventId == null || eventId.isBlank()) {
            eventId = "manual-" + Instant.now().toEpochMilli();
        }

        replayWorkerService.ingest(new CapturedDlqEvent(
                eventId,
                request.dedupKey(),
                request.eventType(),
                request.accountId(),
                request.amount(),
                request.attempt(),
                Instant.ofEpochMilli(request.occurredAtEpochMillis() <= 0 ? Instant.now().toEpochMilli() : request.occurredAtEpochMillis()),
                request.rawPayload()
        ));
        return new ReplayIngestResponse("INGESTED", eventId);
    }

    @PostMapping("/run")
    public ReplayRunResponse run(@RequestBody(required = false) @Valid ReplayRunRequest request) {
        ReplayRunRequest safeRequest = request == null
                ? new ReplayRunRequest(null, null, null, null, null, null, null, null, null, null, null)
                : request;

        ReplayRunResult result = replayWorkerService.run(new ReplayRunCommand(
                safeRequest.accountIdFrom(),
                safeRequest.accountIdTo(),
                safeRequest.eventType(),
                safeRequest.fromEpochMillis(),
                safeRequest.toEpochMillis(),
                safeRequest.batchSize() == null ? properties.getReplay().getBatchSize() : safeRequest.batchSize(),
                safeRequest.rateLimitPerSecond() == null ? properties.getReplay().getRateLimitPerSecond() : safeRequest.rateLimitPerSecond(),
                safeRequest.dryRun() != null && safeRequest.dryRun(),
                resolveOutputTopic(safeRequest.output()),
                safeRequest.operatorName() == null || safeRequest.operatorName().isBlank()
                        ? properties.getReplay().getOperator()
                        : safeRequest.operatorName(),
                safeRequest.notes()
        ));

        return new ReplayRunResponse(
                result.scanned(),
                result.replayed(),
                result.skippedMissingDedup(),
                result.dryRunCount(),
                result.outputTopic()
        );
    }

    private String resolveOutputTopic(String output) {
        String effective = (output == null || output.isBlank()) ? properties.getReplay().getOutput() : output;
        String normalized = effective.toUpperCase(Locale.ROOT);

        if ("MAIN".equals(normalized)) {
            return properties.getTopic().getMain();
        }
        if ("RETRY5S".equals(normalized)) {
            return properties.getTopic().getRetry5s();
        }
        if ("RETRY1M".equals(normalized)) {
            return properties.getTopic().getRetry1m();
        }
        return effective;
    }
}
