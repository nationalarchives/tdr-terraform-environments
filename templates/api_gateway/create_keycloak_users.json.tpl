{
  "openapi" : "3.0.1",
  "info" : {
    "title" : "CreateKeycloakUsersApi",
    "version" : "2022-02-11 12:44:34UTC"
  },

  "paths" : {
    "/users/{userId}" : {
      "delete" : {
        "responses" : {},
        "security" : [ {
          "UserAdminAuthoriser" : [ "email" ]
        } ],
        "x-amazon-apigateway-integration" : {
          "payloadFormatVersion" : "2.0",
          "type" : "aws_proxy",
          "httpMethod" : "POST",
          "uri" : "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/${lambda_arn}/invocations",
          "connectionType" : "INTERNET"
        }
      },
      "parameters" : [ {
        "name" : "userId",
        "in" : "path",
        "description" : "Generated path parameter for userId",
        "required" : true,
        "schema" : {
          "type" : "string"
        }
      } ]
    },
    "/users" : {
      "post" : {
        "responses" : {
          "default" : {
            "description" : "Default response for POST /users"
          }
        },
        "security" : [ {
          "UserAdminAuthoriser" : [ "email" ]
        } ],
        "x-amazon-apigateway-integration" : {
          "payloadFormatVersion" : "2.0",
          "type" : "aws_proxy",
          "httpMethod" : "POST",
          "uri" : "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/${lambda_arn}/invocations",
          "connectionType" : "INTERNET"
        }
      }
    }
  },
  "components" : {
    "securitySchemes" : {
      "UserAdminAuthoriser" : {
        "type" : "oauth2",
        "flows" : { },
        "x-amazon-apigateway-authorizer" : {
          "identitySource" : "$request.header.Authorization",
          "jwtConfiguration" : {
            "audience" : [ "realm-management", "tdr-user-admin" ],
            "issuer" : "${auth_url}/realms/tdr"
          },
          "type" : "jwt"
        }
      }
    }
  },
  "x-amazon-apigateway-importexport-version" : "1.0"
}
