package com.hykes.haidou.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.hykes.haidou.common.error.ApiFailure;
import com.hykes.haidou.repository.DatasetRepository;
import com.hykes.haidou.repository.DatasetRepository.Dataset;
import java.time.Instant;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
public class DatasetService {
    private static final Logger LOG = LoggerFactory.getLogger(DatasetService.class);
    private final DatasetRepository repository;

    public DatasetService(DatasetRepository repository) { this.repository = repository; }

    public Metadata latest() { return metadata(repository.latestVersion()); }

    public Metadata metadata(String version) {
        Dataset release = download(version);
        JsonNode root = release.document();
        JsonNode data = root.path("dataset");
        int schema = root.path("schemaVersion").intValue();
        return new Metadata(version, schema, "simulated", "demo", data.path("gamePatch").asText(null),
                data.path("compiledAt").asText(null), release.publishedAt(), release.checksum(),
                release.bytes().length, "/api/v1/datasets/" + version + "/download", 1,
                root.get("contentPolicy"), List.of(), null, null);
    }

    public Dataset download(String version) {
        Dataset result = repository.read(version);
        JsonNode doc = result.document();
        if (!version.startsWith("demo-") || !doc.path("schemaVersion").isIntegralNumber()
                || doc.path("schemaVersion").intValue() != 1 || !doc.path("dataset").path("mode").asText().equals("demo")) {
            throw ApiFailure.corrupt();
        }
        return result;
    }

    public Health health() {
        var versions = repository.versions();
        int count = 0;
        for (String version : versions) {
            try {
                download(version);
                count++;
            } catch (ApiFailure ignored) {
                // Do not count an incomplete or damaged release as readable.
            }
        }
        try {
            return new Health("UP", latest().datasetVersion(), count);
        } catch (ApiFailure unavailable) {
            LOG.warn("Latest dataset is unavailable; code={}", unavailable.code());
            return new Health("DEGRADED", null, count);
        }
    }

    public record Metadata(String datasetVersion, int schemaVersion, String dataMode, String mode,
            String gamePatch, String compiledAt, Instant publishedAt, String contentChecksum,
            long fileSizeBytes, String downloadUrl, int minClientSchemaVersion, JsonNode contentPolicy,
            List<JsonNode> snapshots, JsonNode coverage, String defaultSnapshotId) {}

    public record Health(String status, String latestDatasetVersion, int datasetCount) {}
}
