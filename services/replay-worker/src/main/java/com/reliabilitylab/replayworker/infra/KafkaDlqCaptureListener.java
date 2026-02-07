package com.reliabilitylab.replayworker.infra;

import com.reliabilitylab.replayworker.app.ReplayWorkerService;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "app.kafka.enabled", havingValue = "true")
public class KafkaDlqCaptureListener {
    private final DlqMessageMapper dlqMessageMapper;
    private final ReplayWorkerService replayWorkerService;

    public KafkaDlqCaptureListener(DlqMessageMapper dlqMessageMapper,
                                   ReplayWorkerService replayWorkerService) {
        this.dlqMessageMapper = dlqMessageMapper;
        this.replayWorkerService = replayWorkerService;
    }

    @KafkaListener(topics = "${app.topic.dlq:account.balance.dlq}", groupId = "${spring.application.name:replay-worker}-capture")
    public void onDlqMessage(ConsumerRecord<String, String> record) {
        replayWorkerService.ingest(dlqMessageMapper.fromRawMessage(record.value()));
    }
}
