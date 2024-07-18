output "pet" {
    value = random_pet.pet.id
}
output "random_string" {
    value = random_string.random.id
}
output "dataset" {
    value = google_healthcare_dataset.dataset.id
}

output "hl7v2store" {
    value = google_healthcare_hl7_v2_store.hl7v2.id
}

output "bucket" {
    value = google_storage_bucket.hl7v2-landing.url
}
output "topic" {
    value = google_pubsub_topic.hl7v2-landing-topic.name
}
output "subscription" {
    value = google_pubsub_subscription.hl7v2-notifications.name
}
