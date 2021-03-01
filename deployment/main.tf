terraform {
  backend "local" {
    path = "/root/tfstate/agent-service-do.tfstate"
  }
}

module "digitalocean" {
    source              = "./droplet"
    servers             = [
        # {
        #     name = "agent-deployment",
        #     type = "s-2vcpu-2gb"
        # }
    ]
    public_key_name     = var.public_key_name
    digital_ocean_key   = var.digital_ocean_key
}
