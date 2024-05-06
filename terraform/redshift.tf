resource "aws_redshift_cluster" "main" {
  cluster_identifier  = lower(local.name_prefix)
  database_name       = "workbench"
  node_type           = "dc2.large"
  cluster_type        = "single-node"
  master_username     = "master"
  master_password     = random_password.redshift.result
  skip_final_snapshot = lower(var.environment) != "production"
  iam_roles           = [aws_iam_role.redshift_service_role.arn]
}

resource "random_password" "redshift" {
  length           = 32
  special          = true
  override_special = "#$%&*()-_=+<>?"
}
