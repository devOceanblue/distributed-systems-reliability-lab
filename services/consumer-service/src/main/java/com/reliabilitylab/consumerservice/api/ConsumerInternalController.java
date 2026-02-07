package com.reliabilitylab.consumerservice.api;

import com.reliabilitylab.consumerservice.app.ConsumerProcessingService;
import com.reliabilitylab.consumerservice.app.ProcessOutcome;
import com.reliabilitylab.consumerservice.app.ProcessingInput;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/internal/consumer")
public class ConsumerInternalController {
    private final ConsumerProcessingService consumerProcessingService;

    public ConsumerInternalController(ConsumerProcessingService consumerProcessingService) {
        this.consumerProcessingService = consumerProcessingService;
    }

    @PostMapping("/process")
    public ConsumeResponse process(@RequestBody @Valid ConsumeRequest request) {
        ProcessOutcome outcome = consumerProcessingService.consume(
                new ProcessingInput(
                        request.eventId(),
                        request.dedupKey(),
                        request.eventType(),
                        request.accountId(),
                        request.amount(),
                        request.rawPayload(),
                        request.topic() == null ? "account.balance.v1" : request.topic(),
                        request.partition(),
                        request.offset(),
                        request.attempt()
                ),
                () -> {
                }
        );
        return new ConsumeResponse(outcome.name());
    }
}
