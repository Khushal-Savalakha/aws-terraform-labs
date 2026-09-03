# --------------------------------------------------------------------------------
#  SOC 2 Compliant RDS Security Group & Instance Setup
# --------------------------------------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "${var.cluster_name}-rds-sg"
  description = "SOC 2 compliant Security Group for RDS PostgreSQL"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "${var.cluster_name}-rds-sg"
  }
}

# Ingress: Allow PostgreSQL connections explicitly from the EKS Cluster Security Group
resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id            = aws_security_group.rds.id
  description                  = "Allow PostgreSQL access strictly from EKS nodes/pods"
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}


resource "aws_db_subnet_group" "main" {
  name       = "${var.cluster_name}-db-subnet-group"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.cluster_name}-db"
  allocated_storage      = 20
  max_allocated_storage  = 100
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t4g.micro"
  db_name                = "appdb"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = false
  publicly_accessible    = false
  storage_encrypted      = true
}