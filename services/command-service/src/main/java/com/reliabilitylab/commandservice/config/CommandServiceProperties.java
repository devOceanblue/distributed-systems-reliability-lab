package com.reliabilitylab.commandservice.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app")
public class CommandServiceProperties {
    private ProduceMode produceMode = ProduceMode.OUTBOX;
    private final Topic topic = new Topic();

    public ProduceMode getProduceMode() {
        return produceMode;
    }

    public void setProduceMode(ProduceMode produceMode) {
        this.produceMode = produceMode;
    }

    public Topic getTopic() {
        return topic;
    }

    public enum ProduceMode {
        OUTBOX,
        DIRECT
    }

    public static class Topic {
        private String accountBalance = "account.balance.v1";

        public String getAccountBalance() {
            return accountBalance;
        }

        public void setAccountBalance(String accountBalance) {
            this.accountBalance = accountBalance;
        }
    }
}
