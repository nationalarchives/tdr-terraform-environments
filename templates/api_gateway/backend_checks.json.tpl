{
  "openapi": "3.0.1",
  "info": {
    "title": "${title}",
    "version": "1"
  },
  "paths": {
    "/": {
      "post": {
        "parameters": [
          {
            "name": "consignmentId",
            "in": "path",
            "required": true,
            "schema": {
              "type": "string"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "200 response",
            "content": {
              "application/json": {
                "schema": {
                  "$ref": "#/components/schemas/Empty"
                }
              }
            }
          }
        },
        "security": [
          {
            "lambda": []
          }
        ],
        "x-amazon-apigateway-integration": {
          "credentials": "${role_arn}",
          "httpMethod": "POST",
          "uri": "arn:aws:apigateway:${region}:states:action/StartExecution",
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
            "application/json": "{\"input\": \"{\\\"consignmentId\\\": \\\"$input.params('consignmentId')\\\"}\",\"stateMachineArn\": \"${state_machine_arn}\"}"
          },
          "passthroughBehavior": "when_no_templates",
          "type": "aws"
        }
      }
    }
  },
  "components": {
    "securitySchemes": {
      "lambda": {
        "type": "apiKey",
        "name": "Authorization",
        "in": "header",
        "x-amazon-apigateway-authtype": "custom",
        "x-amazon-apigateway-authorizer": {
          "authorizerUri": "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/${lambda_arn}/invocations",
          "authorizerResultTtlInSeconds": 0,
          "type": "token"
        }
      }
    }
  }
}
