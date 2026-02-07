package com.reliabilitylab.eventcore.avro;

import org.apache.avro.Schema;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

public final class SchemaResources {
    public static final String EVENT_ENVELOPE = "avro/event-envelope.avsc";
    public static final String ACCOUNT_BALANCE_CHANGED_V1 = "avro/account-balance-changed-v1.avsc";

    private SchemaResources() {
    }

    public static Schema load(String classpathLocation) {
        String schema = loadText(classpathLocation);
        return new Schema.Parser().parse(schema);
    }

    public static String loadText(String classpathLocation) {
        try (InputStream inputStream = SchemaResources.class.getClassLoader().getResourceAsStream(classpathLocation)) {
            if (inputStream == null) {
                throw new IllegalArgumentException("schema resource not found: " + classpathLocation);
            }
            return new String(inputStream.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException ex) {
            throw new IllegalStateException("failed to read schema resource: " + classpathLocation, ex);
        }
    }
}
