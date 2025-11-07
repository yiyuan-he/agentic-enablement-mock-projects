using Amazon.Lambda.Core;

using Amazon.S3;
using Amazon.S3.Model;

[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace LambdaSample;

public class Function
{
    private readonly IAmazonS3 _s3Client;

    public Function()
    {
        _s3Client = new AmazonS3Client();
    }

    public async Task<object> FunctionHandler(object input, ILambdaContext context)
    {
        context.Logger.LogInformation("Serving lambda request.");

        var result = await _s3Client.ListBucketsAsync();
        
        var bucketCount = result.Buckets?.Count ?? 0;
        var responseBody = $"(.NET) Hello lambda - found {bucketCount} buckets.";

        return new
        {
            statusCode = 200,
            statusDescription = "200 OK",
            isBase64Encoded = false,
            headers = new Dictionary<string, string> { { "Content-Type", "text/html" } },
            body = $"<html><body><h1>{responseBody}</h1></body></html>"
        };
    }
}