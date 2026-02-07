package com.reliabilitylab.eventcore.schema;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.avro.Schema;

import java.io.IOException;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Objects;

public final class SchemaRegistryRestClient {
    private static final String CONTENT_TYPE = "application/vnd.schemaregistry.v1+json";

    private final HttpClient httpClient;
    private final ObjectMapper objectMapper;
    private final URI baseUri;

    public SchemaRegistryRestClient(String baseUrl) {
        this(HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(3)).build(), new ObjectMapper(), baseUrl);
    }

    public SchemaRegistryRestClient(HttpClient httpClient, ObjectMapper objectMapper, String baseUrl) {
        this.httpClient = Objects.requireNonNull(httpClient, "httpClient");
        this.objectMapper = Objects.requireNonNull(objectMapper, "objectMapper");
        this.baseUri = URI.create(Objects.requireNonNull(baseUrl, "baseUrl"));
    }

    public int register(String subject, Schema schema) {
        return register(subject, schema.toString());
    }

    public int register(String subject, String schemaJson) {
        String body = "{\"schema\":" + toJsonString(schemaJson) + "}";
        HttpRequest request = HttpRequest.newBuilder(resolve("/subjects/" + encoded(subject) + "/versions"))
                .header("Content-Type", CONTENT_TYPE)
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build();

        JsonNode response = send(request, 200);
        JsonNode id = response.get("id");
        if (id == null || !id.isInt()) {
            throw new SchemaRegistryException("schema registry response did not include id: " + response);
        }
        return id.asInt();
    }

    public String setGlobalCompatibility(String compatibility) {
        String body = "{\"compatibility\":\"" + compatibility + "\"}";
        HttpRequest request = HttpRequest.newBuilder(resolve("/config"))
                .header("Content-Type", CONTENT_TYPE)
                .PUT(HttpRequest.BodyPublishers.ofString(body))
                .build();

        JsonNode response = send(request, 200);
        JsonNode value = response.get("compatibility");
        if (value == null || value.isNull()) {
            throw new SchemaRegistryException("schema registry response did not include compatibility: " + response);
        }
        return value.asText();
    }

    private JsonNode send(HttpRequest request, int expectedStatus) {
        try {
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != expectedStatus) {
                throw new SchemaRegistryException("schema registry call failed status=" + response.statusCode() + " body=" + response.body());
            }
            return objectMapper.readTree(response.body());
        } catch (IOException ex) {
            throw new SchemaRegistryException("schema registry call failed", ex);
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            throw new SchemaRegistryException("schema registry call failed", ex);
        }
    }

    private URI resolve(String path) {
        return baseUri.resolve(path);
    }

    private String encoded(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private String toJsonString(String value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (IOException ex) {
            throw new IllegalStateException("failed to escape schema json", ex);
        }
    }
}
