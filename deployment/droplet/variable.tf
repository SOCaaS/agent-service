variable "digital_ocean_key" {
  description = "your digital ocean token"
}

variable "public_key_name" {
  description = "what is the public key name stored in digital ocean"
  default     = "digitalocean"
}

variable "servers" {
  description = "This is about the server details"
  type        = list(map(string))
  default      = []
}