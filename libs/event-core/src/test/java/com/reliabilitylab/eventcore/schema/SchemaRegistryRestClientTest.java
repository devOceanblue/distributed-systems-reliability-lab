package com.reliabilitylab.eventcore.schema;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import org.apache.avro.Schema;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;
import java.util.concurrent.atomic.AtomicReference;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertThrows;

class SchemaRegistryRestClientTest {
    private HttpServer server;
    private final AtomicReference<String> lastBody = new AtomicReference<>("");

    @BeforeEach
    void setUp() throws IOException {
        server = HttpServer.create(new InetSocketAddress(0), 0);

        server.createContext("/config", exchange -> {
            lastBody.set(readBody(exchange));
            writeJson(exchange, 200, "{\"compatibility\":\"BACKWARD\"}");
        });

        server.createContext("/subjects/account.balance.v1-value/versions", exchange -> {
            lastBody.set(readBody(exchange));
            writeJson(exchange, 200, "{\"id\":101}");
        });

        server.createContext("/subjects/fail-value/versions", exchange -> {
            lastBody.set(readBody(exchange));
            writeJson(exchange, 409, "{\"error_code\":409,\"message\":\"incompatible schema\"}");
        });

        server.start();
    }

    @AfterEach
    void tearDown() {
        if (server != null) {
            server.stop(0);
        }
    }

    @Test
    void shouldSetCompatibilityAndRegisterSchema() {
        String baseUrl = "http://localhost:" + server.getAddress().getPort();
        SchemaRegistryRestClient client = new SchemaRegistryRestClient(baseUrl);

        String compatibility = client.setGlobalCompatibility("BACKWARD");
        assertEquals("BACKWARD", compatibility);
        assertTrue(lastBody.get().contains("compatibility"));

        Schema schema = new Schema.Parser().parse("""
                {
                  "type": "record",
                  "name": "Simple",
                  "fields": [{"name":"value", "type":"string"}]
                }
                """);

        int id = client.register(SchemaSubjects.ACCOUNT_BALANCE_V1_VALUE, schema);
        assertEquals(101, id);
        assertTrue(lastBody.get().contains("\\\"type\\\""));
    }

    @Test
    void shouldFailWhenSchemaRegistryReturnsNonSuccess() {
        String baseUrl = "http://localhost:" + server.getAddress().getPort();
        SchemaRegistryRestClient client = new SchemaRegistryRestClient(baseUrl);

        SchemaRegistryException ex = assertThrows(SchemaRegistryException.class,
                () -> client.register("fail-value", """
                        {"type":"record","name":"Bad","fields":[{"name":"x","type":"string"}]}
                        """));

        assertTrue(ex.getMessage().contains("status=409"));
    }

    private static String readBody(HttpExchange exchange) throws IOException {
        try (InputStream inputStream = exchange.getRequestBody()) {
            return new String(inputStream.readAllBytes(), StandardCharsets.UTF_8);
        }
    }

    private static void writeJson(HttpExchange exchange, int statusCode, String response) throws IOException {
        byte[] body = response.getBytes(StandardCharsets.UTF_8);
        exchange.getResponseHeaders().add("Content-Type", "application/json");
        exchange.sendResponseHeaders(statusCode, body.length);
        try (OutputStream outputStream = exchange.getResponseBody()) {
            outputStream.write(body);
        }
    }
}
