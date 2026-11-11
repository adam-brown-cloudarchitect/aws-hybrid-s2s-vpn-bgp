resource "aws_iam_role" "onprem_router" {
  provider = aws.onprem

  name = "p2-onprem-router"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "onprem_router_ssm" {
  provider = aws.onprem

  role       = aws_iam_role.onprem_router.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "onprem_router" {
  provider = aws.onprem

  name = "p2-onprem-router"
  role = aws_iam_role.onprem_router.name
}
