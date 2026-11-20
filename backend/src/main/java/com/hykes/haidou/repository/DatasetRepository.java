package com.hykes.haidou.repository;

import static java.nio.file.LinkOption.NOFOLLOW_LINKS;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hykes.haidou.common.error.ApiFailure;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;
import java.util.regex.Pattern;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Repository;

@Repository
public class DatasetRepository {
    public static final int MAX_BYTES = 16 * 1024 * 1024;
    private static final Pattern VERSION = Pattern.compile("[a-z0-9]+-[0-9]+\\.[0-9]+");
    private final Path root;
    private final Path pointer;
    private final ObjectMapper mapper;

    public DatasetRepository(ObjectMapper mapper,
            @Value("${haidou.content.base-dir:./content}") String baseDir,
            @Value("${haidou.content.latest-pointer:latest.json}") String pointerFile) {
        this.mapper = mapper;
        this.root = Path.of(baseDir).toAbsolutePath().normalize();
        if (!pointerFile.matches("[a-zA-Z0-9_-]+\\.json") ||
                validVersion(pointerFile.substring(0, pointerFile.length() - 5))) {
            throw new IllegalArgumentException("Invalid latest pointer name");
        }
        this.pointer = root.resolve(pointerFile);
    }

    public Path root() { return root; }
    public Path pointer() { return pointer; }

    public static boolean validVersion(String value) {
        return value != null && value.length() <= 80 && VERSION.matcher(value).matches();
    }

    public static byte[] boundedRead(Path file, int limit) throws IOException {
        if (!Files.isRegularFile(file, NOFOLLOW_LINKS)) throw new IOException("Not a regular file");
        try (var input = Files.newInputStream(file, NOFOLLOW_LINKS)) {
            byte[] result = input.readNBytes(limit + 1);
            if (result.length > limit) throw new IOException("Dataset exceeds size budget");
            return result;
        }
    }

    public JsonNode decode(byte[] bytes) throws IOException {
        JsonNode node = mapper.reader().with(DeserializationFeature.FAIL_ON_TRAILING_TOKENS)
                .with(DeserializationFeature.FAIL_ON_READING_DUP_TREE_KEY).readTree(bytes);
        if (node == null || !node.isObject()) throw new IOException("Expected JSON object");
        return node;
    }

    public String latestVersion() {
        try {
            String value = decode(boundedRead(pointer, 8192)).path("datasetVersion").asText(null);
            if (validVersion(value)) return value;
        } catch (IOException ignored) {
            // An unreadable or absent pointer is not an available latest release.
        }
        throw ApiFailure.notFound();
    }

    public Dataset read(String version) {
        if (!validVersion(version)) throw ApiFailure.badVersion();
        Path file = root.resolve(version + ".json");
        Path sidecar = root.resolve(version + ".sha256");
        if (Files.notExists(file, NOFOLLOW_LINKS)) throw ApiFailure.notFound();
        try {
            byte[] bytes = boundedRead(file, MAX_BYTES);
            String digest = sha256(bytes);
            String expected = new String(boundedRead(sidecar, 128), StandardCharsets.US_ASCII).strip();
            if (!digest.equals(expected)) throw ApiFailure.corrupt();
            JsonNode doc = decode(bytes);
            if (!version.equals(doc.path("dataset").path("datasetVersion").asText())) throw ApiFailure.corrupt();
            return new Dataset(bytes, doc, "sha256:" + digest, Files.getLastModifiedTime(sidecar, NOFOLLOW_LINKS).toInstant());
        } catch (IOException failure) {
            throw ApiFailure.corrupt();
        }
    }

    public List<String> versions() {
        try (var files = Files.list(root)) {
            return files.map(f -> f.getFileName().toString()).filter(s -> s.endsWith(".json"))
                    .map(s -> s.substring(0, s.length() - 5)).filter(DatasetRepository::validVersion).toList();
        } catch (IOException unavailable) {
            return List.of();
        }
    }

    public static String sha256(byte[] bytes) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
        } catch (NoSuchAlgorithmException impossible) {
            throw new IllegalStateException(impossible);
        }
    }

    public record Dataset(byte[] bytes, JsonNode document, String checksum, Instant publishedAt) {}
}
