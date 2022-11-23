terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "3.11.0"
    }

    env = {
      source  = "tchupp/env"
      version = "0.0.2"
    }
  }
}


provider "env" {}

