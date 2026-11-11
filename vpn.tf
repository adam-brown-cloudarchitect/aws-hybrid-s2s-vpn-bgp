resource "random_password" "tunnel1" {
  length  = 48
  lower   = true
  upper   = true
  numeric = false
  special = false
}

resource "random_password" "tunnel2" {
  length  = 48
  lower   = true
  upper   = true
  numeric = false
  special = false
}

resource "aws_eip" "onprem_router" {
  provider = aws.onprem

  domain = "vpc"

  tags = {
    Name = "p2-onprem-router"
  }
}

resource "aws_customer_gateway" "onprem" {
  bgp_asn    = 65010
  ip_address = aws_eip.onprem_router.public_ip
  type       = "ipsec.1"

  tags = {
    Name = "p2-onprem"
  }
}

resource "aws_vpn_connection" "onprem" {
  customer_gateway_id = aws_customer_gateway.onprem.id
  transit_gateway_id  = data.terraform_remote_state.project1.outputs.transit_gateway_id
  type                = "ipsec.1"
  static_routes_only  = true

  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]

  tunnel2_ike_versions                 = ["ikev2"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [14]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]

  tunnel1_inside_cidr   = "169.254.10.0/30"
  tunnel2_inside_cidr   = "169.254.11.0/30"
  tunnel1_preshared_key = random_password.tunnel1.result
  tunnel2_preshared_key = random_password.tunnel2.result

  tags = {
    Name = "p2-onprem"
  }
}
