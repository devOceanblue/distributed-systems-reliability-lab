package com.reliabilitylab.commandservice;

import com.reliabilitylab.eventcore.EventEnvelopeBuilder;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;
import org.springframework.context.annotation.Bean;

import java.time.Clock;

@SpringBootApplication
@ConfigurationPropertiesScan
public class CommandServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(CommandServiceApplication.class, args);
    }

    @Bean
    EventEnvelopeBuilder eventEnvelopeBuilder(Clock clock) {
        return new EventEnvelopeBuilder(clock);
    }

    @Bean
    Clock clock() {
        return Clock.systemUTC();
    }
}
