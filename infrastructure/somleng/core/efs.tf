# EFS filesystem for sharing SIP gateway XML files between Switch and FreeSWITCH.
# Switch writes gateway configs; FreeSWITCH reads them via profile rescan.

resource "aws_efs_file_system" "sip_gateways" {
  creation_token = "somleng-sip-gateways"
  encrypted      = true

  tags = {
    Name = "somleng-sip-gateways"
  }
}

resource "aws_security_group" "efs_sip_gateways" {
  name   = "somleng-efs-sip-gateways"
  vpc_id = module.hydrogen_region.vpc.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [module.hydrogen_region.vpc.vpc_cidr_block]
    description = "NFS from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "somleng-efs-sip-gateways"
  }
}

# Mount targets in each private subnet so ECS tasks can reach EFS
resource "aws_efs_mount_target" "sip_gateways" {
  for_each = toset(module.hydrogen_region.vpc.private_subnets)

  file_system_id  = aws_efs_file_system.sip_gateways.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs_sip_gateways.id]
}
