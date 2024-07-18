provider "google-beta" {
  project     = "${var.project_id}"
  region      = "${var.region}"
}
provider "google" {
  project     = "${var.project_id}"
  region      = "${var.region}"
}

resource "random_pet" "pet" {
  keepers = {
    project_id = "${var.project_id}"
  }
}

resource "random_string" "random" {
  length = 16
  special = false
  upper = false

  keepers = {
    project_id = "${var.project_id}"
  }
}

resource "google_healthcare_dataset" "dataset" {
  provider = google
  name      = "${random_pet.pet.id}-${random_string.random.id}"
  location  = "us-central1"
  time_zone = "UTC"
}

resource "google_healthcare_hl7_v2_store" "hl7v2" {

  name = "${random_pet.pet.id}-hl7v2"
  dataset = google_healthcare_dataset.dataset.id
}

resource "google_storage_bucket" "hl7v2-landing" {
  name          = "${random_pet.pet.id}-${random_string.random.id}"
  location      = "US"
  force_destroy = true

  uniform_bucket_level_access = true
  public_access_prevention = "enforced"
}

resource "google_pubsub_topic" "hl7v2-landing-topic" {
  name = "${random_pet.pet.id}-hl7v2-landing-topic"
}

resource "google_storage_notification" "notification" {
  bucket         = google_storage_bucket.hl7v2-landing.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.hl7v2-landing-topic.id
  event_types    = ["OBJECT_FINALIZE", "OBJECT_METADATA_UPDATE"]
  custom_attributes = {
    new-attribute = "new-attribute-value"
  }
  depends_on = [google_pubsub_topic_iam_binding.binding]
}

data "google_storage_project_service_account" "gcs_account" {
}

resource "google_pubsub_topic_iam_binding" "binding" {
  topic   = google_pubsub_topic.hl7v2-landing-topic.id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

resource "google_pubsub_subscription" "hl7v2-notifications" {
  name  = "${google_pubsub_topic.hl7v2-landing-topic.name}-sub"
  topic = google_pubsub_topic.hl7v2-landing-topic.name

  # 1 day
  message_retention_duration = "86400s"
  retain_acked_messages      = true

  ack_deadline_seconds = 20

  expiration_policy {
    ttl = "300000.5s"
  }
  retry_policy {
    minimum_backoff = "10s"
  }

  enable_message_ordering    = false
}

