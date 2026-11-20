package com.hykes.haidou.controller;

import com.hykes.haidou.common.api.ApiResponse;
import com.hykes.haidou.service.DatasetService;
import com.hykes.haidou.service.DatasetService.Health;
import com.hykes.haidou.service.DatasetService.Metadata;
import java.time.Duration;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.context.request.WebRequest;

@RestController
@RequestMapping("/api/v1")
public class DatasetController {
    private static final CacheControl LATEST = CacheControl.maxAge(Duration.ofSeconds(60));
    private static final CacheControl IMMUTABLE = CacheControl.maxAge(Duration.ofDays(365)).cachePublic().immutable();
    private final DatasetService service;

    public DatasetController(DatasetService service) { this.service = service; }

    @GetMapping("/health")
    public ResponseEntity<ApiResponse<Health>> health() {
        return ResponseEntity.ok().cacheControl(CacheControl.noStore()).body(ApiResponse.ok(service.health()));
    }

    @GetMapping("/datasets/latest")
    public ResponseEntity<ApiResponse<Metadata>> latest() {
        return ResponseEntity.ok().cacheControl(LATEST).body(ApiResponse.ok(service.latest()));
    }

    @GetMapping("/datasets/{datasetVersion}")
    public ApiResponse<Metadata> version(@PathVariable String datasetVersion) {
        return ApiResponse.ok(service.metadata(datasetVersion));
    }

    @GetMapping("/datasets/{datasetVersion}/download")
    public ResponseEntity<byte[]> download(@PathVariable String datasetVersion, WebRequest request) {
        var release = service.download(datasetVersion);
        String etag = '"' + release.checksum() + '"';
        if (request.checkNotModified(etag)) {
            return ResponseEntity.status(304).cacheControl(IMMUTABLE).eTag(etag).build();
        }
        return ResponseEntity.ok().contentType(MediaType.APPLICATION_JSON).cacheControl(IMMUTABLE)
                .eTag(etag).contentLength(release.bytes().length).body(release.bytes());
    }
}
