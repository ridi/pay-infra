resource "aws_iam_role" "ecs_tasks_trust_role" {
  assume_role_policy = "${data.aws_iam_policy_document.ecs_tasks_trust_policy.json}"
}

data "aws_iam_policy_document" "ecs_tasks_trust_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
