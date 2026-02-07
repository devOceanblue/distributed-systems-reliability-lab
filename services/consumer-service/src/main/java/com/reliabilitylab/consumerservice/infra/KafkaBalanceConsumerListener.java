package com.reliabilitylab.consumerservice.infra;

import com.reliabilitylab.consumerservice.app.ConsumerProcessingService;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(name = "app.kafka.enabled", havingValue = "true")
public class KafkaBalanceConsumerListener {
    private final ConsumerMessageMapper consumerMessageMapper;
    private final ConsumerProcessingService consumerProcessingService;

    public KafkaBalanceConsumerListener(ConsumerMessageMapper consumerMessageMapper,
                                        ConsumerProcessingService consumerProcessingService) {
        this.consumerMessageMapper = consumerMessageMapper;
        this.consumerProcessingService = consumerProcessingService;
    }

    @KafkaListener(
            topics = "${app.topic.main:account.balance.v1}",
            groupId = "${app.consumer-group:consumer-service}",
            containerFactory = "manualAckKafkaListenerContainerFactory"
    )
    public void onMessage(ConsumerRecord<String, String> record, Acknowledgment acknowledgment) {
        consumerProcessingService.consume(
                consumerMessageMapper.fromRecord(record),
                acknowledgment::acknowledge
        );
    }
}
