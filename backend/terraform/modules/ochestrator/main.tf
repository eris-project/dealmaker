locals {
  app_name = "${var.app_name}-ochestrator"
}

module "eventbridge" {
  source  = "terraform-aws-modules/eventbridge/aws"

  bus_name = "${local.app_name}-bus"

  rules = {
    orders_create = {
      description = "Capture all created orders",
      event_pattern = jsonencode({
        "detail-type" : ["order-create"],
        "source" : ["api.gateway.orders.create"]
      })
    }
  }

  create_role = false
  role_name = module.eventbridge_role.iam_role_name

  targets = {
    orders_create = [
      {
        name            = "test-app-lambda"
        arn             = "arn:aws:lambda:us-east-1:824536865920:function:test-app-lambda"
        target_id       = "test-app-lambda"
      }
    ]
  }
}


module "eventbridge_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 4.0"

  create_role = true

  role_name         = "eventbridge-to-lambda-role"
  role_requires_mfa = false

  trusted_role_services = ["events.amazonaws.com"]

  custom_role_policy_arns = [
    module.apigateway_put_events_to_eventbridge_policy.arn
  ]
}

module "eventbridge_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 4.0"

  name        = "eventbridge-to-lambda-policy"

  policy = data.aws_iam_policy_document.event_bridge_policy_document.json
}

data "aws_iam_policy_document" "event_bridge_policy_document" {
  statement {
    sid       = "AllowTriggerLambda"
    actions   = ["lambda:InvokeFunction"]
    resources = ["arn:aws:lambda:us-east-1:824536865920:function:test-app-lambda"]
  }
}



resource "random_pet" "this" {
  length = 2
}

module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 0"

  name          = "${random_pet.this.id}-http"
  description   = "My ${random_pet.this.id} HTTP API Gateway"
  protocol_type = "HTTP"

  create_api_domain_name = false

  integrations = {
    "POST /orders/create" = {
      integration_type    = "AWS_PROXY"
      integration_subtype = "EventBridge-PutEvents"
      credentials_arn     = module.apigateway_put_events_to_eventbridge_role.iam_role_arn

      request_parameters = jsonencode({
        EventBusName = module.eventbridge.eventbridge_bus_name,
        Source       = "api.gateway.orders.create",
        DetailType   = "order-create",
        Detail       = "$request.body",
        Time         = "$context.requestTimeEpoch"
      })

      payload_format_version = "1.0"
    }
  }
}

module "apigateway_put_events_to_eventbridge_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version = "~> 4.0"

  create_role = true

  role_name         = "apigateway-put-events-to-eventbridge"
  role_requires_mfa = false

  trusted_role_services = ["apigateway.amazonaws.com"]

  custom_role_policy_arns = [
    module.apigateway_put_events_to_eventbridge_policy.arn
  ]
}

module "apigateway_put_events_to_eventbridge_policy" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
  version = "~> 4.0"

  name        = "apigateway-put-events-to-eventbridge"
  description = "Allow PutEvents to EventBridge"

  policy = data.aws_iam_policy_document.apigateway_put_events_to_eventbridge_policy.json
}

data "aws_iam_policy_document" "apigateway_put_events_to_eventbridge_policy" {
  statement {
    sid       = "AllowPutEvents"
    actions   = ["events:PutEvents"]
    resources = [module.eventbridge.eventbridge_bus_arn]
  }

  depends_on = [module.eventbridge]
}

# resource "aws_sqs_queue" "dlq" {
#   name = "${random_pet.this.id}-dlq"
# }

# resource "aws_sqs_queue" "queue" {
#   name = random_pet.this.id
# }

# resource "aws_sqs_queue_policy" "queue" {
#   queue_url = aws_sqs_queue.queue.id
#   policy    = data.aws_iam_policy_document.queue.json
# }

# data "aws_iam_policy_document" "queue" {
#   statement {
#     sid     = "AllowSendMessage"
#     actions = ["sqs:SendMessage"]

#     principals {
#       type        = "Service"
#       identifiers = ["events.amazonaws.com"]
#     }

#     resources = [aws_sqs_queue.queue.arn]
#   }
# }