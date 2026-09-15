mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
}

run "protected_state_backend" {
  command = plan
  assert {
    condition     = aws_s3_bucket_versioning.state.versioning_configuration[0].status == "Enabled"
    error_message = "O bucket precisa de versionamento."
  }
  assert {
    condition     = aws_s3_bucket_public_access_block.state.block_public_acls && aws_s3_bucket_public_access_block.state.block_public_policy && aws_s3_bucket_public_access_block.state.ignore_public_acls && aws_s3_bucket_public_access_block.state.restrict_public_buckets
    error_message = "As quatro proteções de acesso público devem estar ativas."
  }
  assert {
    condition     = alltrue([for rule in aws_s3_bucket_server_side_encryption_configuration.state.rule : rule.apply_server_side_encryption_by_default[0].sse_algorithm == "AES256"])
    error_message = "O state precisa de criptografia AES256."
  }
  assert {
    condition     = aws_dynamodb_table.locks.hash_key == "LockID" && alltrue([for attr in aws_dynamodb_table.locks.attribute : attr.name == "LockID" && attr.type == "S"])
    error_message = "LockID precisa ser a chave String do DynamoDB."
  }
  assert {
    condition     = local.bucket_name == "6322006-technova-tfstate-123456789012-us-east-1"
    error_message = "O bucket deve ser específico do aluno, conta e região."
  }
}

