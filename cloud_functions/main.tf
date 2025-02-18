# main.tf
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"  # use a recent version
    }
  }
}

provider "google" {
  project = "sublime-flux-414616"
  region  = "us-central1"       # or any supported region for Cloud Functions
}

# main.tf (continued)

# Storage bucket for function source code
resource "google_storage_bucket" "function_code_bucket" {
  name     = "${var.project_id}-function-src"   # bucket name must be globally unique
  location = var.region
}

# Archive the function source code directory into a zip file
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/function-src"   # path to your function source folder
  output_path = "${path.module}/function-src.zip"
}

# Upload the zipped code to the Storage bucket
resource "google_storage_bucket_object" "function_zip_object" {
  name   = "function-src.zip"
  bucket = google_storage_bucket.function_code_bucket.name
  source = data.archive_file.function_zip.output_path
}

# main.tf (continued)

# Cloud Function resource
resource "google_cloudfunctions_function" "hello_function" {
  name        = "hello-function"                  # The name of your Cloud Function
  description = "A simple Hello World HTTP function"
  runtime     = "nodejs14"                        # Runtime language
  entry_point = "helloWorld"                      # Function in code to invoke
  trigger_http = true                             # Indicates this is an HTTP-triggered function
  available_memory_mb   = 128                     # Memory allocation
  source_archive_bucket = google_storage_bucket.function_code_bucket.name
  source_archive_object = google_storage_bucket_object.function_zip_object.name
}

# main.tf (continued)

# IAM policy to allow public (unauthenticated) access to the function
resource "google_cloudfunctions_function_iam_member" "all_users_invoker" {
  project        = var.project_id
  region         = var.region
  cloud_function = google_cloudfunctions_function.hello_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}

# main.tf (continued)

output "function_url" {
  description = "The HTTPS endpoint of the Cloud Function"
  value       = google_cloudfunctions_function.hello_function.https_trigger_url
}