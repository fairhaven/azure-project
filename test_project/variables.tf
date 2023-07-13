
#resource group variable
variable "rsgname" {
  type        = string
  description = "Resource group name"
  default     = "test-resourceGroup"
}

#region variable
variable "location" {
  type        = string
  description = "testing location variable"
  default     = "westeurope"
}

#storage account variable which is uniqued globally
#variable "stractname" {
#type        = string
# description = "uniqued storage account name"
#}

variable "prefix" {
  type        = string
  default     = "win-vm-iis"
  description = "Prefix of the resource name"
}