package com.reliabilitylab.replayworker;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class ReplayWorkerApplication {
    public static void main(String[] args) {
        SpringApplication.run(ReplayWorkerApplication.class, args);
    }
}
