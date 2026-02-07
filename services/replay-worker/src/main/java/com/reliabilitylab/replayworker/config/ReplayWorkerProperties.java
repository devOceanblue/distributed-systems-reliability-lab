package com.reliabilitylab.replayworker.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties(prefix = "app")
public class ReplayWorkerProperties {
    private final Kafka kafka = new Kafka();
    private final Topic topic = new Topic();
    private final Replay replay = new Replay();

    public Kafka getKafka() {
        return kafka;
    }

    public Topic getTopic() {
        return topic;
    }

    public Replay getReplay() {
        return replay;
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

    public static class Replay {
        private int batchSize = 100;
        private int rateLimitPerSecond = 10;
        private String output = "MAIN";
        private String operator = "system";

        public int getBatchSize() {
            return batchSize;
        }

        public void setBatchSize(int batchSize) {
            this.batchSize = batchSize;
        }

        public int getRateLimitPerSecond() {
            return rateLimitPerSecond;
        }

        public void setRateLimitPerSecond(int rateLimitPerSecond) {
            this.rateLimitPerSecond = rateLimitPerSecond;
        }

        public String getOutput() {
            return output;
        }

        public void setOutput(String output) {
            this.output = output;
        }

        public String getOperator() {
            return operator;
        }

        public void setOperator(String operator) {
            this.operator = operator;
        }
    }
}
