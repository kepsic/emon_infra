variable "access_key" {
  default     = "<access_key_not_set>"
  type        = string
  description = "access_key for AWS"

}
variable "secret_key" {
  default     = "<secret_key_not_set>"
  type        = string
  description = "secret_key for AWS"
}

variable "region" {
  default = "eu-north-1"
}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = var.region
}

resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-lampstack-lock"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}