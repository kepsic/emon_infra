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

resource "aws_s3_bucket" "bucket" {
  bucket = "lampstack-terraformbackend"
}