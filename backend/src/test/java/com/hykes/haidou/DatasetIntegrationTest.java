package com.hykes.haidou;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.hykes.haidou.controller.ApiErrors;
import com.hykes.haidou.controller.DatasetController;
import com.hykes.haidou.repository.DatasetRepository;
import com.hykes.haidou.service.DatasetPublisher;
import com.hykes.haidou.service.DatasetService;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class DatasetIntegrationTest {
    private static final String API = "/api/v1";
    private static final Path DEMO = Path.of("..", "\u539f\u578b\u56fe", "data", "demo-0.1.json");
    @TempDir Path temp;
    private final ObjectMapper mapper = new ObjectMapper().findAndRegisterModules();
    private Path releases;
    private DatasetPublisher publisher;
    private MockMvc mvc;

    @BeforeEach void setup() throws Exception {
        releases = temp.resolve("content");
        var repository = new DatasetRepository(mapper, releases.toString(), "latest.json");
        var service = new DatasetService(repository);
        publisher = new DatasetPublisher(repository, service, mapper);
        mvc = MockMvcBuilders.standaloneSetup(new DatasetController(service)).setControllerAdvice(new ApiErrors()).build();
    }

    @Test void emptyContentAndVersionErrors() throws Exception {
        mvc.perform(get(API + "/health")).andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("DEGRADED"));
        mvc.perform(get(API + "/datasets/latest")).andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(40401));
        mvc.perform(get(API + "/datasets/demo-0.x")).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value(40001));
        mvc.perform(get(API + "/datasets/demo-9.9/download")).andExpect(status().isNotFound())
                .andExpect(jsonPath("$.code").value(40401));
    }

    @Test void publishedBytesMetadataAndConditionalDownload() throws Exception {
        publisher.publish(DEMO, false);
        byte[] bytes = Files.readAllBytes(DEMO);
        String checksum = "sha256:" + DatasetRepository.sha256(bytes);
        String etag = '"' + checksum + '"';
        mvc.perform(get(API + "/health")).andExpect(jsonPath("$.data.status").value("UP"));
        mvc.perform(get(API + "/datasets/latest")).andExpect(status().isOk())
                .andExpect(header().string("Cache-Control", "max-age=60"))
                .andExpect(jsonPath("$.data.dataMode").value("simulated"))
                .andExpect(jsonPath("$.data.contentChecksum").value(checksum))
                .andExpect(jsonPath("$.data.fileSizeBytes").value(bytes.length))
                .andExpect(jsonPath("$.data.gamePatch").isEmpty());
        mvc.perform(get(API + "/datasets/demo-0.1")).andExpect(status().isOk())
                .andExpect(jsonPath("$.data.datasetVersion").value("demo-0.1"));
        mvc.perform(get(API + "/datasets/demo-0.1/download")).andExpect(status().isOk())
                .andExpect(content().bytes(bytes)).andExpect(header().string("ETag", etag));
        mvc.perform(get(API + "/datasets/demo-0.1/download").header("If-None-Match", etag))
                .andExpect(status().isNotModified()).andExpect(header().string("ETag", etag))
                .andExpect(content().bytes(new byte[0]));
    }

    @Test void rejectsBrokenAndInvalidPacksAndIsolatesFixtures() throws Exception {
        publisher.publish(DEMO, false);
        var broken = demo("demo-0.2");
        ((ObjectNode) broken.path("championAugments").get(0)).put("augmentId", "missing");
        Path source = write("broken.json", broken);
        assertThatThrownBy(() -> publisher.publish(source, false)).hasMessageContaining("Dataset rejected");
        publisher.publish(source, true);
        assertThat(releases.resolve("fixtures/demo-0.2.json")).isRegularFile();
        assertThat(releases.resolve("fixtures/reports/demo-0.2.report.json")).isRegularFile();
        mvc.perform(get(API + "/datasets/demo-0.2")).andExpect(status().isNotFound());
        var invalid = demo("demo-0.3");
        var stats = ((ObjectNode) invalid.path("championAugments").get(0)).putObject("stats");
        stats.put("wins", 5).put("games", 1).put("isSimulated", true);
        assertThatThrownBy(() -> publisher.publish(write("invalid.json", invalid), true)).hasMessageContaining("Dataset rejected");
        mvc.perform(get(API + "/datasets/latest")).andExpect(jsonPath("$.data.datasetVersion").value("demo-0.1"));
    }

    @Test void rollbackLeavesVersionsReadableAndCorruptionIsReported() throws Exception {
        publisher.publish(DEMO, false);
        var second = demo("demo-0.2");
        publisher.publish(write("second.json", second), false);
        ObjectNode changed = second.deepCopy();
        ((ObjectNode) changed.path("dataset")).put("gamePatch", "changed");
        assertThatThrownBy(() -> publisher.publish(write("conflict.json", changed), false)).hasMessageContaining("immutable");
        publisher.rollback("demo-0.1");
        mvc.perform(get(API + "/datasets/latest")).andExpect(jsonPath("$.data.datasetVersion").value("demo-0.1"));
        mvc.perform(get(API + "/datasets/demo-0.2/download")).andExpect(status().isOk());
        Files.writeString(releases.resolve("demo-0.1.json"), "{}");
        mvc.perform(get(API + "/datasets/latest")).andExpect(status().isInternalServerError()).andExpect(jsonPath("$.code").value(50001));
        mvc.perform(get(API + "/health")).andExpect(jsonPath("$.data.status").value("DEGRADED"))
                .andExpect(jsonPath("$.data.datasetCount").value(1));
    }

    private ObjectNode demo(String version) throws Exception {
        var root = (ObjectNode) mapper.readTree(Files.readAllBytes(DEMO));
        ((ObjectNode) root.path("dataset")).put("datasetVersion", version);
        return root;
    }

    private Path write(String file, ObjectNode data) throws Exception {
        return Files.write(temp.resolve(file), mapper.writeValueAsBytes(data));
    }
}
