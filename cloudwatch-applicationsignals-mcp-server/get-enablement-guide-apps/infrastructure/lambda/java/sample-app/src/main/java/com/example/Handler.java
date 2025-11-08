package com.example;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.ApplicationLoadBalancerRequestEvent;
import com.amazonaws.services.lambda.runtime.events.ApplicationLoadBalancerResponseEvent;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.ListBucketsResponse;

public class Handler implements RequestHandler<ApplicationLoadBalancerRequestEvent, ApplicationLoadBalancerResponseEvent> {
    
    private final S3Client s3Client = S3Client.create();

    @Override
    public ApplicationLoadBalancerResponseEvent handleRequest(ApplicationLoadBalancerRequestEvent event, Context context) {
        context.getLogger().log("Serving lambda request.");

        ListBucketsResponse result = s3Client.listBuckets();
        
        int bucketCount = result.buckets() != null ? result.buckets().size() : 0;
        String responseBody = String.format("(Java) Hello lambda - found %d buckets.", bucketCount);

        ApplicationLoadBalancerResponseEvent response = new ApplicationLoadBalancerResponseEvent();
        response.setStatusCode(200);
        response.setHeaders(java.util.Map.of("Content-Type", "text/html"));
        response.setBody(String.format("<html><body><h1>%s</h1></body></html>", responseBody));
        response.setIsBase64Encoded(false);
        
        return response;
    }
}