{
  "swagger" : "2.0",
  "info" : {
    "description" : "API Gateway for Draft Metadata validation",
    "version" : "0.0.1",
    "title" : "${title}"
  },
  "basePath" : "/${environment}",
  "schemes" : [ "https" ],
  "paths" : {
    "/draft-metadata/validate/{consignmentId+}" : {
      "post" : {
        "consumes": [
          "application/json"
        ],
        "produces": [
          "application/json"
        ],
        "parameters": [
          {
            "name": "consignmentId",
            "in": "path",
            "required": true,
            "type": "string"
          }
        ],
        "responses": {
          "200": {
            "description": "200 response",
            "schema": {
              "$ref": "#/definitions/Empty"
            }
          }
        },
        "security": [
          {
            "lambda": []
          }
        ],
        "x-amazon-apigateway-request-validator" : "Validate query string parameters and headers",
        "x-amazon-apigateway-integration": {
          "uri": "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/${lambda_arn}/invocations",
          "responses": {
            "default": {
              "statusCode": "200"
            }
          },
          "requestParameters": {
            "integration.request.header.Accept-Encoding": "'identity'",
            "integration.request.header.Content-Type": "'application/x-amz-json-1.1'"
          },
          "requestTemplates": {
            "application/json": "{\"input\": \"{\\\"consignmentId\\\": \\\"$input.params('consignmentId')\\\"}\"}"
          },
          "passthroughBehavior": "when_no_match",
          "httpMethod": "POST",
          "type": "aws"
        }
      }
    }
  },
  "definitions" : {
    "Empty" : {
      "type" : "object",
      "title" : "Empty Schema"
    }
  },
  "x-amazon-apigateway-request-validators" : {
    "Validate query string parameters and headers" : {
      "validateRequestParameters" : true,
      "validateRequestBody" : false
    }
  },
  "securityDefinitions": {
    "lambda": {
      "type": "apiKey",
      "name": "Authorization",
      "in": "header",
      "x-amazon-apigateway-authtype": "custom",
      "x-amazon-apigateway-authorizer": {
        "authorizerUri": "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/${authoriser_lambda_arn}/invocations",
        "authorizerResultTtlInSeconds": 0,
        "type": "token"
      }
    }
  }
}
