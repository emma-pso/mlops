# main.tf

# --------------------------------------------------------------------------------------------------
# DEFINE PROJECT, SERVICE ACCOUNT, AND GITHUB VARIABLES
# --------------------------------------------------------------------------------------------------

variable "project_id" {
  description = "The ID of the Google Cloud project."
  type        = string
  default     = "ml-terraform-465317"
}

variable "gcs_bucket_location" {
  description = "The location for the GCS bucket."
  type        = string
  default     = "US-CENTRAL1"
}

locals {
  service_account_id   = "mlops-demo"
  service_account_name = "MLOps Demo Service Account"
  github_owner         = "emma-pso"
  repo_name            = "mlops"
  bucket_name          = "mlops_test_emma-${var.project_id}" # Bucket name construction
  roles = [
    "roles/artifactregistry.writer",
    "roles/bigquery.readSessionUser",
    "roles/bigquery.user",
    "roles/bigquery.dataViewer",
    "roles/cloudbuild.builds.builder",
    "roles/cloudbuild.tokenAccessor",
    "roles/cloudbuild.workerPoolUser",
    "roles/logging.logWriter",
    "roles/iam.serviceAccountUser",
    "roles/aiplatform.user",
    "roles/developerconnect.user",
    "roles/storage.objectCreator",
  ]
}

# --------------------------------------------------------------------------------------------------
# CREATE THE WORKLOAD IDENTITY POOL AND OIDC PROVIDER
# --------------------------------------------------------------------------------------------------

resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = var.project_id
  workload_identity_pool_id = "github"
  display_name              = "GitHub Actions Pool"
}

resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  location                           = "global"
  workload_identity_pool_provider_id = "my-repo"
  display_name                       = "My GitHub repo Provider"
  attribute_mapping = {
    "google.subject"         = "assertion.sub"
    "attribute.actor"        = "assertion.actor"
    "attribute.repository"   = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
  }
  attribute_condition = "attribute.repository == '${local.github_owner}/${local.repo_name}'"
  issuer_uri          = "https://token.actions.githubusercontent.com"
}
# --------------------------------------------------------------------------------------------------
# CREATE THE GCS BUCKET
# --------------------------------------------------------------------------------------------------

resource "google_storage_bucket" "mlops_bucket" {
  name          = local.bucket_name
  project       = var.project_id
  location      = var.gcs_bucket_location
  force_destroy = true # Set to false for production environments

  uniform_bucket_level_access = true
}

# --------------------------------------------------------------------------------------------------
# CREATE THE SERVICE ACCOUNT
# --------------------------------------------------------------------------------------------------

resource "google_service_account" "mlops_service_account" {
  project      = var.project_id
  account_id   = local.service_account_id
  display_name = local.service_account_name
}

# --------------------------------------------------------------------------------------------------
# GRANT IAM ROLES TO THE SERVICE ACCOUNT ON THE PROJECT
# --------------------------------------------------------------------------------------------------

resource "google_project_iam_member" "mlops_service_account_roles" {
  for_each = toset(local.roles)

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.mlops_service_account.email}"
}

# --------------------------------------------------------------------------------------------------
# ALLOW GITHUB TO IMPERSONATE THE SERVICE ACCOUNT
# --------------------------------------------------------------------------------------------------

resource "google_service_account_iam_member" "github_impersonation" {
  service_account_id = google_service_account.mlops_service_account.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${local.github_owner}/${local.repo_name}"
}

# --------------------------------------------------------------------------------------------------
# OUTPUTS
# --------------------------------------------------------------------------------------------------

output "service_account_email" {
  description = "The email of the created service account."
  value       = google_service_account.mlops_service_account.email
}

output "workload_identity_provider" {
  description = "The full name of the Workload Identity Provider."
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}
