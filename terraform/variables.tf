

variable "vm_connector_name" { 
  description = "ZTW connector name for the VM. This is optional for demo."
  type = string
}

variable "vm_connector_token" { 
  description = "ZTW connector token for the VM. This is optional for demo."  
  type = string
}

variable "kind_connector_name" { 
  description = "ZTW connector name for the kind cluster"
  type = string
}

variable "kind_connector_token" {
  description = "ZTW connector token for the kind cluster"  
  type = string
}

variable "deployment_name" {
  description = "ZTW deployment name, which is used for AWS label "  
  type = string
  default = "ztna_demo"
}


variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "aws_profile" {
  description = "AWS profile"
  type        = string
  default     = "aad-sso-sjcrd02"
}
