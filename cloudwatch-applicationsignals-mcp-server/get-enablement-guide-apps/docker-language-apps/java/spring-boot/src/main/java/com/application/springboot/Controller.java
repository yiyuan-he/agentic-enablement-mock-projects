package com.application.springboot;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.ListBucketsResponse;

@RestController
public class Controller {
    private static final Logger logger = LoggerFactory.getLogger(Controller.class);
    private final S3Client s3Client;

    public Controller() {
        this.s3Client = S3Client.builder().build();
    }

    @GetMapping("/")
    public String index() {
        return healthCheck();
    }

    @GetMapping("/health")
    public String healthCheck() {
        String msg = "OK";
        logger.info(msg);
        return msg;
    }

    @GetMapping("/api/buckets")
    public String listBuckets() {
        try {
            ListBucketsResponse response = s3Client.listBuckets();
            logger.info("Logging Buckets from ListBuckets Result:");
            response.buckets().forEach(bucket -> logger.info(bucket.name()));
            return "done aws sdk s3 request";
        } catch (Exception e) {
            logger.error("Exception thrown when Listing Buckets: " + e.getMessage());
            return "error: " + e.getMessage();
        }
    }
}
