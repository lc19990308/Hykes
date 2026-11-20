package com.hykes.haidou.common.error;

import org.springframework.http.HttpStatus;

public final class ApiFailure extends RuntimeException {
    private final HttpStatus status;
    private final int code;

    private ApiFailure(HttpStatus status, int code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }

    public HttpStatus status() { return status; }
    public int code() { return code; }

    public static ApiFailure badVersion() {
        return new ApiFailure(HttpStatus.BAD_REQUEST, 40001, "Invalid dataset version");
    }

    public static ApiFailure notFound() {
        return new ApiFailure(HttpStatus.NOT_FOUND, 40401, "Dataset unavailable");
    }

    public static ApiFailure corrupt() {
        return new ApiFailure(HttpStatus.INTERNAL_SERVER_ERROR, 50001, "Dataset integrity check failed");
    }
}
