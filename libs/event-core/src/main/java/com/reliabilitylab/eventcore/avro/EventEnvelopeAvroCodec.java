package com.reliabilitylab.eventcore.avro;

import com.reliabilitylab.eventcore.EventEnvelope;
import com.reliabilitylab.eventcore.EventValidator;
import org.apache.avro.Schema;
import org.apache.avro.generic.GenericData;
import org.apache.avro.generic.GenericDatumReader;
import org.apache.avro.generic.GenericDatumWriter;
import org.apache.avro.generic.GenericRecord;
import org.apache.avro.io.BinaryDecoder;
import org.apache.avro.io.BinaryEncoder;
import org.apache.avro.io.DecoderFactory;
import org.apache.avro.io.EncoderFactory;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

public final class EventEnvelopeAvroCodec {
    private final Schema schema;

    public EventEnvelopeAvroCodec() {
        this(SchemaResources.load(SchemaResources.EVENT_ENVELOPE));
    }

    public EventEnvelopeAvroCodec(Schema schema) {
        this.schema = schema;
    }

    public Schema schema() {
        return schema;
    }

    public byte[] encode(EventEnvelope envelope) {
        EventEnvelope validated = EventValidator.validate(envelope);
        GenericRecord record = toGenericRecord(validated);

        GenericDatumWriter<GenericRecord> writer = new GenericDatumWriter<>(schema);
        try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
            BinaryEncoder encoder = EncoderFactory.get().binaryEncoder(outputStream, null);
            writer.write(record, encoder);
            encoder.flush();
            return outputStream.toByteArray();
        } catch (IOException ex) {
            throw new IllegalStateException("failed to encode envelope", ex);
        }
    }

    public EventEnvelope decode(byte[] bytes) {
        GenericDatumReader<GenericRecord> reader = new GenericDatumReader<>(schema);
        BinaryDecoder decoder = DecoderFactory.get().binaryDecoder(bytes, null);

        try {
            GenericRecord record = reader.read(null, decoder);
            EventEnvelope envelope = new EventEnvelope(
                    required(record, "event_id"),
                    required(record, "dedup_key"),
                    required(record, "event_type"),
                    (Integer) record.get("schema_version"),
                    (Long) record.get("occurred_at"),
                    nullable(record, "trace_id"),
                    required(record, "payload")
            );
            return EventValidator.validate(envelope);
        } catch (IOException ex) {
            throw new IllegalStateException("failed to decode envelope", ex);
        }
    }

    private GenericRecord toGenericRecord(EventEnvelope envelope) {
        GenericRecord record = new GenericData.Record(schema);
        record.put("event_id", envelope.eventId());
        record.put("dedup_key", envelope.dedupKey());
        record.put("event_type", envelope.eventType());
        record.put("schema_version", envelope.schemaVersion());
        record.put("occurred_at", envelope.occurredAt());
        record.put("trace_id", envelope.traceId());
        record.put("payload", envelope.payloadJson());
        return record;
    }

    private static String required(GenericRecord record, String field) {
        Object value = record.get(field);
        if (value == null) {
            throw new IllegalStateException(field + " is null in decoded record");
        }
        return value.toString();
    }

    private static String nullable(GenericRecord record, String field) {
        Object value = record.get(field);
        return value == null ? null : value.toString();
    }
}
