package com.reliabilitylab.consumerservice.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app")
public class ConsumerServiceProperties {
    private String consumerGroup = "consumer-service";
    private IdempotencyMode idempotencyMode = IdempotencyMode.PROCESSED_TABLE;
    private OffsetCommitMode offsetCommitMode = OffsetCommitMode.AFTER_DB;
    private String forcePermanentErrorOnAccountId = "";
    private CacheInvalidationMode cacheInvalidationMode = CacheInvalidationMode.DEL;
    private final Kafka kafka = new Kafka();
    private final Topic topic = new Topic();

    public String getConsumerGroup() {
        return consumerGroup;
    }

    public void setConsumerGroup(String consumerGroup) {
        this.consumerGroup = consumerGroup;
    }

    public IdempotencyMode getIdempotencyMode() {
        return idempotencyMode;
    }

    public void setIdempotencyMode(IdempotencyMode idempotencyMode) {
        this.idempotencyMode = idempotencyMode;
    }

    public OffsetCommitMode getOffsetCommitMode() {
        return offsetCommitMode;
    }

    public void setOffsetCommitMode(OffsetCommitMode offsetCommitMode) {
        this.offsetCommitMode = offsetCommitMode;
    }

    public String getForcePermanentErrorOnAccountId() {
        return forcePermanentErrorOnAccountId;
    }

    public void setForcePermanentErrorOnAccountId(String forcePermanentErrorOnAccountId) {
        this.forcePermanentErrorOnAccountId = forcePermanentErrorOnAccountId;
    }

    public CacheInvalidationMode getCacheInvalidationMode() {
        return cacheInvalidationMode;
    }

    public void setCacheInvalidationMode(CacheInvalidationMode cacheInvalidationMode) {
        this.cacheInvalidationMode = cacheInvalidationMode;
    }

    public Kafka getKafka() {
        return kafka;
    }

    public Topic getTopic() {
        return topic;
    }

    public enum IdempotencyMode {
        PROCESSED_TABLE,
        NONE
    }

    public enum OffsetCommitMode {
        BEFORE_DB,
        AFTER_DB
    }

    public enum CacheInvalidationMode {
        DEL,
        NONE
    }

    public static class Kafka {
        private boolean enabled;

        public boolean isEnabled() {
            return enabled;
        }

        public void setEnabled(boolean enabled) {
            this.enabled = enabled;
        }
    }

    public static class Topic {
        private String main = "account.balance.v1";
        private String retry5s = "account.balance.retry.5s";
        private String retry1m = "account.balance.retry.1m";
        private String dlq = "account.balance.dlq";

        public String getMain() {
            return main;
        }

        public void setMain(String main) {
            this.main = main;
        }

        public String getRetry5s() {
            return retry5s;
        }

        public void setRetry5s(String retry5s) {
            this.retry5s = retry5s;
        }

        public String getRetry1m() {
            return retry1m;
        }

        public void setRetry1m(String retry1m) {
            this.retry1m = retry1m;
        }

        public String getDlq() {
            return dlq;
        }

        public void setDlq(String dlq) {
            this.dlq = dlq;
        }
    }
}
