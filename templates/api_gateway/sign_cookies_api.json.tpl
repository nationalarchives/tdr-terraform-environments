{
  "swagger" : "2.0",
  "info" : {
    "version" : "0.0.1",
    "title" : "${title}"
  },
  "basePath" : "/${environment}",
  "schemes" : [ "https" ],
  "paths" : {
    "/cookies" : {
      "get" : {
        "produces" : [ "application/json" ],
        "responses" : {
          "200" : {
            "description" : "200 response",
            "schema" : {
              "$ref" : "#/definitions/Empty"
            },
            "headers" : {
              "Access-Control-Allow-Origin" : {
                "type" : "string"
              },
              "Access-Control-Allow-Credentials" : {
                "type" : "string"
              }
            }
          }
        },
        "x-amazon-apigateway-integration" : {
          "type" : "aws_proxy",
          "httpMethod" : "POST",
          "uri" : "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/${lambda_arn}/invocations",
          "responses" : {
            "default" : {
              "statusCode" : "200",
              "responseParameters" : {
                "method.response.header.Access-Control-Allow-Origin" : "'${upload_cors_urls}'"
              }
            }
          },
          "passthroughBehavior" : "when_no_match",
          "contentHandling" : "CONVERT_TO_TEXT"
        }
      },
      "options" : {
        "consumes" : [ "application/json" ],
        "produces" : [ "application/json" ],
        "responses" : {
          "200" : {
            "description" : "200 response",
            "schema" : {
              "$ref" : "#/definitions/Empty"
            },
            "headers" : {
              "Access-Control-Allow-Origin" : {
                "type" : "string"
              },
              "Access-Control-Allow-Methods" : {
                "type" : "string"
              },
              "Access-Control-Allow-Credentials" : {
                "type" : "string"
              },
              "Access-Control-Allow-Headers" : {
                "type" : "string"
              }
            }
          }
        },
        "x-amazon-apigateway-integration" : {
          "type" : "mock",
          "responses" : {
            "default" : {
              "statusCode" : "200",
              "responseParameters" : {
                "method.response.header.Access-Control-Allow-Credentials" : "'true'",
                "method.response.header.Access-Control-Allow-Methods" : "'GET,OPTIONS'",
                "method.response.header.Access-Control-Allow-Headers" : "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
                "method.response.header.Access-Control-Allow-Origin" : "'${upload_cors_urls}'"
              },
              "responseTemplates" : {
                "application/json" : "#if( $input.params('origin') == 'https://app.tdr-local.nationalarchives.gov.uk:9000' && $context.stage == 'intg') #set($context.responseOverride.header.Access-Control-Allow-Origin = 'https://app.tdr-local.nationalarchives.gov.uk:9000') #elseif( $input.params('origin').contains('sharepoint.com')) #set($context.responseOverride.header.Access-Control-Allow-Origin = $input.params('origin'))#end"
              }
            }
          },
          "requestTemplates" : {
            "application/json" : "{\"statusCode\": 200}"
          },
          "passthroughBehavior" : "when_no_match"
        }
      }
    }
  },
  "definitions" : {
    "Empty" : {
      "type" : "object",
      "title" : "Empty Schema"
    }
  }
}
