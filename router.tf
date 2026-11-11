data "aws_ssm_parameter" "ubuntu_2404_ami" {
  provider = aws.onprem

  name = "/aws/service/canonical/ubuntu/server/noble/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

resource "aws_security_group" "onprem_router" {
  provider = aws.onprem

  name        = "p2-onprem-router"
  description = "Allow Site-to-Site VPN traffic and outbound router management"
  vpc_id      = aws_vpc.onprem.id

  ingress {
    description = "IKE from AWS VPN tunnels"
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = [
      "${aws_vpn_connection.onprem.tunnel1_address}/32",
      "${aws_vpn_connection.onprem.tunnel2_address}/32",
    ]
  }

  ingress {
    description = "IPsec NAT traversal from AWS VPN tunnels"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = [
      "${aws_vpn_connection.onprem.tunnel1_address}/32",
      "${aws_vpn_connection.onprem.tunnel2_address}/32",
    ]
  }

  egress {
    description = "IKE to AWS VPN tunnel endpoints"
    from_port   = 500
    to_port     = 500
    protocol    = "udp"
    cidr_blocks = [
      "${aws_vpn_connection.onprem.tunnel1_address}/32",
      "${aws_vpn_connection.onprem.tunnel2_address}/32",
    ]
  }

  egress {
    description = "IPsec NAT traversal to AWS VPN tunnel endpoints"
    from_port   = 4500
    to_port     = 4500
    protocol    = "udp"
    cidr_blocks = [
      "${aws_vpn_connection.onprem.tunnel1_address}/32",
      "${aws_vpn_connection.onprem.tunnel2_address}/32",
    ]
  }

  egress {
    description = "HTTPS for SSM, bootstrap, and package downloads"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP for Ubuntu package repositories during bootstrap"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "p2-onprem-router"
  }
}

resource "aws_instance" "onprem_router" {
  provider = aws.onprem

  #checkov:skip=CKV_AWS_88: The customer-gateway router requires a public EIP for AWS VPN tunnel termination; ingress is limited to the AWS tunnel endpoints.
  #checkov:skip=CKV_AWS_126: This short-lived v0.1 lab uses basic monitoring; detailed monitoring adds cost and is not needed for tunnel/path validation.
  #checkov:skip=CKV_AWS_135: Enabling EBS optimization forces replacement of the active v0.1 router; defer this setting to a planned rebuild.
  ami                         = data.aws_ssm_parameter.ubuntu_2404_ami.value
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.onprem_public.id
  vpc_security_group_ids      = [aws_security_group.onprem_router.id]
  iam_instance_profile        = aws_iam_instance_profile.onprem_router.name
  associate_public_ip_address = true
  source_dest_check           = false
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted             = true
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
  }

  #checkov:skip=CKV_SECRET_6: v0.1 places tunnel PSKs in user data and state; v0.2 will use SSM SecureString.
  user_data = templatefile("${path.module}/templates/router-user-data.sh.tftpl", {
    customer_gateway_public_ip = aws_eip.onprem_router.public_ip
    tunnel1_address            = aws_vpn_connection.onprem.tunnel1_address
    tunnel1_cgw_inside_address = aws_vpn_connection.onprem.tunnel1_cgw_inside_address
    tunnel1_preshared_key      = random_password.tunnel1.result
    tunnel2_address            = aws_vpn_connection.onprem.tunnel2_address
    tunnel2_cgw_inside_address = aws_vpn_connection.onprem.tunnel2_cgw_inside_address
    tunnel2_preshared_key      = random_password.tunnel2.result
  })

  depends_on = [aws_iam_role_policy_attachment.onprem_router_ssm]

  tags = {
    Name = "p2-onprem-router"
  }
}

resource "aws_eip_association" "onprem_router" {
  provider = aws.onprem

  allocation_id = aws_eip.onprem_router.id
  instance_id   = aws_instance.onprem_router.id
}
