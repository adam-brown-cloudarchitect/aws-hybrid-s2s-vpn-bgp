resource "aws_ec2_transit_gateway_route_table" "onprem" {
  transit_gateway_id = data.terraform_remote_state.project1.outputs.transit_gateway_id

  tags = {
    Name = "p2-onprem"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "onprem" {
  transit_gateway_attachment_id  = aws_vpn_connection.onprem.transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.onprem.id
}

resource "aws_ec2_transit_gateway_route" "app" {
  destination_cidr_block         = "10.100.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.onprem.id
  transit_gateway_attachment_id  = data.terraform_remote_state.project1.outputs.inspection_attachment_id
}

resource "aws_ec2_transit_gateway_route" "shared" {
  destination_cidr_block         = "10.200.0.0/16"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.onprem.id
  transit_gateway_attachment_id  = data.terraform_remote_state.project1.outputs.inspection_attachment_id
}

resource "aws_ec2_transit_gateway_route" "onprem_return" {
  destination_cidr_block         = "172.16.0.0/16"
  transit_gateway_route_table_id = data.terraform_remote_state.project1.outputs.tgw_route_table_ids["inspection"]
  transit_gateway_attachment_id  = aws_vpn_connection.onprem.transit_gateway_attachment_id
}