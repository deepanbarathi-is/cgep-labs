terraform {
  required_version = ">= 1.6"
  required_providers {
    google = { source = "hashicorp/google", version = "~> 5.0" }
  }
}

provider "google" {
  project = "tough-talent-255206"
  region  = "us-central1"
}

module "data_bucket" {
  source = "../../modules/compliant-gcs-bucket"

  gcp_project        = "tough-talent-255206"
  project_label      = "cgep-lab"
  environment        = "dev"
  retention_days     = 30
  bucket_name_suffix = "dev-data-dbp"
}

output "attestation" { value = module.data_bucket.compliance_attestation }
output "bucket_url"  { value = module.data_bucket.bucket_url }
output "kms_key_id"  { value = module.data_bucket.kms_key_id }