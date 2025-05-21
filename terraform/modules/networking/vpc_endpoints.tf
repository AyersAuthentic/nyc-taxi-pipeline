resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"

  # Attach to every private route table
  route_table_ids = module.vpc.private_route_table_ids

  tags = merge(var.tags, { Name = "s3-gateway-endpoint" })
}

