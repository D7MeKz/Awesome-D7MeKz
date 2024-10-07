variable "name" {
  description = "Identifier for the scenario, used to uniquely name resources."
  type        = string
  default     = "test"
}

variable "image_name" {
  description = "The name of the image to use for the instance."
  type        = string
  default     = "focal-server-cloudimg-amd64"
}

variable "flavor_name" {
  description = "The flavor to use for the instance."
  type        = string
  default     = "m1.medium"
}

variable "subnet_cidr" {
  description = "The CIDR block for the subnet."
  type        = string
  default     = "10.0.2.0/24"
}

variable "port_security_enabled" {
  description = "Enable or disable port security on the network."
  type        = bool
  default     = true
}

variable "allowed_ports" {
  description = "List of maps defining allowed ports for the security group. Each map should include protocol, port_range_min, port_range_max, and optionally remote_ip_prefix."
  type = list(object({
    protocol         = string
    port_range_min   = number
    port_range_max   = number
    remote_ip_prefix = optional(string, "0.0.0.0/0")
  }))
  default = [
    {
      protocol       = "tcp"
      port_range_min = 22
      port_range_max = 22
    },
    {
      protocol       = "tcp"
      port_range_min = 80
      port_range_max = 80
    },
    {
      protocol       = "tcp"
      port_range_min = 443
      port_range_max = 443
    },
    {
      protocol       = "tcp"
      port_range_min = 18080
      port_range_max = 18080
    }
  ]
}

variable "pubkey_file_path" {
  type    = string
  default = "~/.ssh/test.pub"
}
