provider "google" {
  project     = var.project_id
  region      = "europe-north1"
}

resource "google_storage_bucket" "main" {
  name          = "ahus-demo-1-bucket"
  location      = "EU"
}

resource "google_storage_bucket" "converted" {
  name          = "ahus-demo-1-converted"
  location      = "EU"
}

resource "google_pubsub_topic" "main" {
  name = "workshop2"
}

resource "google_pubsub_topic_iam_binding" "binding" {
  topic   = google_pubsub_topic.main.id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

data "google_storage_project_service_account" "gcs_account" {
}

resource "google_storage_notification" "main" {
  bucket = google_storage_bucket.main.name
  payload_format = "JSON_API_V1"
  topic = google_pubsub_topic.main.id
  event_types = [ "OBJECT_FINALIZE" ]

  depends_on = [
    google_pubsub_topic_iam_binding.binding
  ]
}
