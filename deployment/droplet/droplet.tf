data "digitalocean_ssh_key" "ssh_key_id" {
  name = var.public_key_name
}

data "digitalocean_ssh_key" "ssh_key_id2" {
  name = "digitalocean"
}

resource "digitalocean_droplet" "server" {
  count             = length(var.servers)
  image             = "ubuntu-20-04-x64"
  name              = var.servers[count.index]["name"]
  region            = "sgp1"
  size              = var.servers[count.index]["type"]
  ssh_keys          = [data.digitalocean_ssh_key.ssh_key_id.id, data.digitalocean_ssh_key.ssh_key_id2.id] # ssh key id
  private_networking = true
}