package com.hykes.haidou.controller;

import com.hykes.haidou.common.api.ApiResponse;
import com.hykes.haidou.common.error.ApiFailure;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.CacheControl;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice(assignableTypes = DatasetController.class)
public class ApiErrors {
    private static final Logger LOG = LoggerFactory.getLogger(ApiErrors.class);

    @ExceptionHandler(ApiFailure.class)
    public ResponseEntity<ApiResponse<Void>> known(ApiFailure failure) {
        if (failure.status().is5xxServerError()) LOG.warn("Dataset request failed integrity checks");
        return ResponseEntity.status(failure.status()).cacheControl(CacheControl.noStore())
                .body(ApiResponse.error(failure.code(), failure.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> unexpected(Exception failure) {
        LOG.error("Unexpected dataset request failure", failure);
        return ResponseEntity.internalServerError().cacheControl(CacheControl.noStore())
                .body(ApiResponse.error(50000, "Service unavailable"));
    }
}
