package com.reliabilitylab.eventcore.avro;

import com.reliabilitylab.eventcore.EventEnvelope;
import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericDatumWriter;
import org.apache.avro.generic.GenericRecord;
import org.apache.avro.io.BinaryEncoder;
import org.apache.avro.io.EncoderFactory;
import org.junit.jupiter.api.Test;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class EventEnvelopeAvroCodecTest {

    @Test
    void shouldEncodeDecodeRoundTrip() {
        EventEnvelopeAvroCodec codec = new EventEnvelopeAvroCodec();

        EventEnvelope source = new EventEnvelope(
                "evt-1",
                "tx-1",
                "AccountBalanceChanged",
                1,
                1767225600000L,
                "trace-1",
                "{\"accountId\":\"A-1\",\"amount\":100}"
        );

        byte[] encoded = codec.encode(source);
        EventEnvelope decoded = codec.decode(encoded);

        assertEquals(source.eventId(), decoded.eventId());
        assertEquals(source.dedupKey(), decoded.dedupKey());
        assertEquals(source.eventType(), decoded.eventType());
        assertEquals(source.schemaVersion(), decoded.schemaVersion());
        assertEquals(source.occurredAt(), decoded.occurredAt());
        assertEquals(source.traceId(), decoded.traceId());
        assertEquals(source.payloadJson(), decoded.payloadJson());
    }

    @Test
    void shouldFailWhenDedupKeyMissing() {
        EventEnvelopeAvroCodec codec = new EventEnvelopeAvroCodec();

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> codec.encode(new EventEnvelope(
                        "evt-2",
                        "",
                        "AccountBalanceChanged",
                        1,
                        1767225600000L,
                        "trace-2",
                        "{}"
                )));

        assertEquals("dedup_key is required", ex.getMessage());
    }

    @Test
    void shouldFailWhenConsumerSeesBlankDedupKey() {
        EventEnvelopeAvroCodec codec = new EventEnvelopeAvroCodec();
        Schema schema = codec.schema();

        GenericRecord record = new GenericData.Record(schema);
        record.put("event_id", "evt-3");
        record.put("dedup_key", " ");
        record.put("event_type", "AccountBalanceChanged");
        record.put("schema_version", 1);
        record.put("occurred_at", 1767225600000L);
        record.put("trace_id", "trace-3");
        record.put("payload", "{}");

        byte[] encoded = encodeRaw(schema, record);
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> codec.decode(encoded));

        assertEquals("dedup_key is required", ex.getMessage());
    }

    private static byte[] encodeRaw(Schema schema, GenericRecord record) {
        GenericDatumWriter<GenericRecord> writer = new GenericDatumWriter<>(schema);
        try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
            BinaryEncoder encoder = EncoderFactory.get().binaryEncoder(outputStream, null);
            writer.write(record, encoder);
            encoder.flush();
            return outputStream.toByteArray();
        } catch (IOException ex) {
            throw new IllegalStateException("failed to encode raw record", ex);
        }
    }
}
