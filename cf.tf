data "archive_file" "cf" {
  type        = "zip"
  source_dir  = "cf"
  output_path = "${path.root}/cf.zip"
}

resource "google_storage_bucket" "cf" {
  name     = "ahus-workshop-sc-cf"
  location = "EU"
}

resource "google_storage_bucket_object" "cfobj" {
  name   = "${data.archive_file.cf.output_md5}.zip"
  bucket = google_storage_bucket.cf.name
  source = "${path.root}/cf.zip"
}

resource "google_service_account" "cf" {
  account_id = "cf-workshop"
}

resource "google_project_iam_member" "main" {
  for_each = toset(["roles/cloudfunctions.serviceAgent"])

  role   = each.key
  member = "serviceAccount:${google_service_account.cf.email}"
}

resource "google_cloudfunctions_function" "main" {
  name        = "convert-to-base64"
  description = "Process files from pubsub"
  runtime     = "go113"
  region      = "europe-west1"

  source_archive_bucket = google_storage_bucket.cf.name
  source_archive_object = google_storage_bucket_object.cfobj.name

  service_account_email = google_service_account.cf.email
  
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.main.id
  }

  entry_point = "Workshop"
}
