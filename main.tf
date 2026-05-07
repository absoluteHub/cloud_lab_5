terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  credentials = file("terraform-key.json")
  project     = "lab4-web-server-v3"
  region      = "europe-west4"
  zone        = "europe-west4-a"
}

resource "google_compute_firewall" "web_firewall" {
  name    = "allow-http-terraform"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

resource "google_compute_instance" "web_instance" {
  name         = "lab6-web-server"
  machine_type = "e2-micro"
  zone         = "europe-west4-a"
  tags         = ["web-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "andrii:${file("~/.ssh/gcp_key.pub")}"
    startup-script = <<-EOT
      #!/bin/bash
      apt-get update
      apt-get install docker.io -y
      systemctl start docker
      systemctl enable docker
      docker run -d -p 80:80 --name my-web-app valindervalll/lab5-app:latest
      docker run -d --name watchtower -v /var/run/docker.sock:/var/run/docker.sock -e DOCKER_API_VERSION=1.44 containrrr/watchtower --interval 30 my-web-app
    EOT
  }
}
