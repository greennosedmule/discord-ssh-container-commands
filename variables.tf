variable "api_gateway_stage_name" {
  type    = string
  default = "main"
}

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "resource_prefix" {
  type        = string
  default     = ""
  description = "The string to prefix all resources with to avoid naming collisions with multiple deployments in the same region."
}

variable "ssh_destination_host" {
  type        = string
  description = "The FQDN of the host to run commands on."
}

variable "ssh_destination_port" {
  type        = number
  default     = 22
  description = "The SSH port of the host to run commands on."
}

variable "ssh_proxy_host" {
  type        = string
  description = "The FQDN of the proxy jump host used to reach the destination host."
}

variable "ssh_proxy_port" {
  type        = number
  default     = 22
  description = "The SSH port of the proxy jump host used to reach the destination host."
}

variable "discord_public_key" {
  type        = string
  description = "Discord integration public key.  Used to authorize requests."
}
