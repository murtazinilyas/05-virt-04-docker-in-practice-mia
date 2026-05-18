
resource "yandex_container_registry_iam_binding" "puller" {
  registry_id = var.registry_id
  role        = "container-registry.images.puller"

  members = [
    "system:allUsers",
  ]
}