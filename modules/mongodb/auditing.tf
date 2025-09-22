resource "mongodbatlas_auditing" "database_audit" {
  project_id = mongodbatlas_project.this.id
  audit_filter = jsonencode({
    atype           = ["authenticate", "authCheck", "createCollection", "dropCollection", "dropDatabase", "dropUser", "dropAllUsersFromDatabase", "shutdown", "applicationMessage"]
    "param.command" = ["find", "insert", "delete", "update", "findAndModify"]
  })
  audit_authorization_success = false
  enabled                     = var.db_audit_enable
}
