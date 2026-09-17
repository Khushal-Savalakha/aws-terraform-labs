resource "aws_db_instance" "default" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  password_wo          = var.db_password
  password_wo_version  = 1
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
}

