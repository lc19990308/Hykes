package com.hykes.haidou.service;

import static java.nio.file.LinkOption.NOFOLLOW_LINKS;
import static java.nio.file.StandardCopyOption.ATOMIC_MOVE;
import static java.nio.file.StandardCopyOption.REPLACE_EXISTING;
import static java.nio.file.StandardOpenOption.CREATE;
import static java.nio.file.StandardOpenOption.WRITE;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.hykes.haidou.repository.DatasetRepository;
import com.networknt.schema.JsonSchema;
import com.networknt.schema.JsonSchemaFactory;
import com.networknt.schema.SpecVersion;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.springframework.stereotype.Service;

@Service
public class DatasetPublisher {
    private static final List<String> IDENTIFIED = List.of("champions", "augments", "items", "summonerSpells", "builds", "sources");
    private final DatasetRepository repository;
    private final DatasetService service;
    private final ObjectMapper mapper;
    private final JsonSchema schema;

    public DatasetPublisher(DatasetRepository repository, DatasetService service, ObjectMapper mapper) throws IOException {
        this.repository = repository;
        this.service = service;
        this.mapper = mapper;
        try (var input = DatasetPublisher.class.getResourceAsStream("/schema/demo-1.json")) {
            schema = JsonSchemaFactory.getInstance(SpecVersion.VersionFlag.V202012).getSchema(input);
        }
    }

    public String publish(Path source, boolean fixture) throws IOException {
        byte[] bytes = DatasetRepository.boundedRead(source, DatasetRepository.MAX_BYTES);
        JsonNode doc = repository.decode(bytes);
        String version = doc.path("dataset").path("datasetVersion").asText(null);
        if (!DatasetRepository.validVersion(version)) throw new IllegalArgumentException("Invalid dataset version");
        var validation = validate(doc);
        boolean accepted = validation.errors().isEmpty() && (fixture || validation.brokenReferences().isEmpty());
        String checksum = DatasetRepository.sha256(bytes);
        return locked(() -> {
            Path base = fixture ? repository.root().resolve("fixtures") : repository.root();
            Path reportDir = base.resolve(accepted ? "reports" : "rejected");
            ensureDirectory(base);
            ensureDirectory(reportDir);
            Path report = reportDir.resolve(version + (accepted ? "" : "-" + checksum.substring(0, 12)) + ".report.json");
            if (!accepted) {
                writeReport(report, version, fixture, false, checksum, validation);
                throw new IllegalArgumentException("Dataset rejected; validation report: " + report);
            }
            Path bundle = base.resolve(version + ".json");
            Path sidecar = base.resolve(version + ".sha256");
            if (Files.exists(bundle, NOFOLLOW_LINKS)) {
                byte[] previous = DatasetRepository.boundedRead(bundle, DatasetRepository.MAX_BYTES);
                if (!java.util.Arrays.equals(previous, bytes)) {
                    throw new IllegalStateException("A published dataset version is immutable");
                }
            } else {
                atomicWrite(bundle, bytes);
            }
            writeReport(report, version, fixture, true, checksum, validation);
            if (!Files.exists(sidecar, NOFOLLOW_LINKS)) {
                atomicWrite(sidecar, (checksum + "\n").getBytes(StandardCharsets.US_ASCII));
            } else if (!checksum.equals(new String(DatasetRepository.boundedRead(sidecar, 128), StandardCharsets.US_ASCII).strip())) {
                throw new IllegalStateException("Existing checksum disagrees with release");
            }
            if (!fixture) {
                service.download(version);
                setLatest(version);
            }
            return fixture ? "Isolated fixture: " + version : "Published: " + version + " sha256:" + checksum;
        });
    }

    public String rollback(String version) throws IOException {
        return locked(() -> {
            service.download(version);
            setLatest(version);
            return "Latest dataset: " + version;
        });
    }

    private Validation validate(JsonNode doc) {
        var errors = new ArrayList<>(schema.validate(doc).stream().map(Object::toString).sorted().toList());
        var broken = new ArrayList<String>();
        if (!errors.isEmpty()) return new Validation(errors, broken);
        Map<String, Set<String>> ids = new HashMap<>();
        Set<String> assets = new HashSet<>();
        for (String domain : IDENTIFIED) {
            var known = new HashSet<String>();
            ids.put(domain, known);
            for (JsonNode entity : doc.path(domain)) {
                String id = entity.path("id").asText();
                if (!known.add(id)) errors.add("Duplicate ID: " + domain + "/" + id);
                if (entity.hasNonNull("assetKey") && !assets.add(entity.path("assetKey").asText())) {
                    errors.add("Duplicate assetKey: " + entity.path("assetKey").asText());
                }
            }
        }
        for (String domain : IDENTIFIED) {
            int index = 0;
            for (JsonNode entity : doc.path(domain)) {
                String owner = domain + "/" + index++;
                references(broken, ids.get("sources"), entity.path("sourceIds"), owner + "/sourceIds");
                if (domain.equals("champions")) references(broken, ids.get("summonerSpells"), entity.path("summonerSpells"), owner + "/summonerSpells");
                if (!domain.equals("builds")) continue;
                reference(broken, ids.get("champions"), entity.path("championId"), owner + "/championId");
                Set<String> items = ids.get("items");
                references(broken, items, entity.path("coreItemIds"), owner + "/coreItemIds");
                for (JsonNode starter : entity.path("startingItems")) reference(broken, items, starter.path("itemId"), owner + "/startingItems");
                if (entity.hasNonNull("boots")) reference(broken, items, entity.path("boots").path("itemId"), owner + "/boots");
                for (JsonNode alternate : entity.path("alternatives")) {
                    reference(broken, items, alternate.path("replaceItemId"), owner + "/alternatives/replaceItemId");
                    reference(broken, items, alternate.path("withItemId"), owner + "/alternatives/withItemId");
                }
            }
        }
        references(broken, ids.get("sources"), doc.path("dataset").path("sourceIds"), "dataset/sourceIds");
        int index = 0;
        Set<List<String>> relations = new HashSet<>();
        for (JsonNode relation : doc.path("championAugments")) {
            String owner = "championAugments/" + index++;
            var championId = relation.path("championId");
            var augmentId = relation.path("augmentId");
            reference(broken, ids.get("champions"), championId, owner + "/championId");
            reference(broken, ids.get("augments"), augmentId, owner + "/augmentId");
            references(broken, ids.get("sources"), relation.path("sourceIds"), owner + "/sourceIds");
            if (!relations.add(List.of(championId.asText(), augmentId.asText()))) errors.add("Duplicate relation: " + owner);
        }
        for (String domain : List.of("champions", "augments", "items", "championAugments", "builds")) {
            validateStats(doc.path(domain), "$/" + domain, errors);
        }
        return new Validation(errors, broken);
    }

    private static void validateStats(JsonNode value, String path, List<String> errors) {
        if (value.isObject()) {
            JsonNode stats = value.get("stats");
            if (stats != null && !stats.isNull()) {
                if (!stats.isObject() || !stats.path("isSimulated").isBoolean() || !stats.path("isSimulated").booleanValue()) {
                    errors.add("Expected simulated stats at " + path);
                }
                if (stats.hasNonNull("wins") || stats.hasNonNull("games")) {
                    var wins = stats.path("wins");
                    var games = stats.path("games");
                    if (!wins.isIntegralNumber() || !games.isIntegralNumber() || !wins.canConvertToInt() || !games.canConvertToInt()
                            || games.asInt() <= 0 || wins.asInt() < 0 || wins.asInt() > games.asInt()) {
                        errors.add("Invalid wins or games at " + path);
                    }
                }
            }
            value.fields().forEachRemaining(f -> validateStats(f.getValue(), path + "/" + f.getKey(), errors));
        } else if (value.isArray()) {
            for (int i = 0; i < value.size(); i++) validateStats(value.get(i), path + "/" + i, errors);
        }
    }

    private static void references(List<String> broken, Set<String> ids, JsonNode many, String path) {
        for (JsonNode id : many) reference(broken, ids, id, path);
    }

    private static void reference(List<String> broken, Set<String> ids, JsonNode id, String path) {
        if (!id.isTextual() || !ids.contains(id.textValue())) broken.add(path + ": " + id.asText());
    }

    private void writeReport(Path file, String version, boolean fixture, boolean ok, String checksum, Validation result) throws IOException {
        atomicWrite(file, mapper.writerWithDefaultPrettyPrinter().writeValueAsBytes(Map.of(
                "datasetVersion", version, "fixture", fixture, "accepted", ok, "sha256", checksum,
                "checkedAt", Instant.now().toString(), "errors", result.errors(), "brokenReferences", result.brokenReferences())));
    }

    private void setLatest(String version) throws IOException {
        atomicWrite(repository.pointer(), mapper.writeValueAsBytes(Map.of("datasetVersion", version)));
    }

    private <T> T locked(IoTask<T> operation) throws IOException {
        ensureDirectory(repository.root());
        Path lock = repository.root().resolve(".publish.lock");
        try (var channel = FileChannel.open(lock, CREATE, WRITE, NOFOLLOW_LINKS);
             var held = channel.lock()) {
            return operation.run();
        }
    }

    private static void ensureDirectory(Path directory) throws IOException {
        Files.createDirectories(directory);
        if (!Files.isDirectory(directory, NOFOLLOW_LINKS)) throw new IOException("Not a regular directory");
    }

    private static void atomicWrite(Path file, byte[] bytes) throws IOException {
        Path temp = Files.createTempFile(file.getParent(), ".publish-", ".tmp");
        try {
            Files.write(temp, bytes);
            Files.move(temp, file, ATOMIC_MOVE, REPLACE_EXISTING);
        } finally {
            Files.deleteIfExists(temp);
        }
    }

    @FunctionalInterface
    private interface IoTask<T> { T run() throws IOException; }
    private record Validation(List<String> errors, List<String> brokenReferences) {}
}
