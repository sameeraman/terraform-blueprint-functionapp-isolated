
variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

variable "company_prefix" {
  description = "(Required) environment prefix"
  type        = string
}

variable "environment_prefix" {
  description = "(Required) environment prefix"
  type        = string
}

variable "location_prefix" {
  description = "(Required) location prefix"
  type        = string
}

variable "workload_postfix" {
  description = "(Required) workload postfix"
  type        = string
}

variable "location" {
  description = "(Required) Location to deploy the resources"
  type        = string
}

variable "tags" {
  description = "(Optional) Tags for categorization"
  type        = map(any)
  default     = {}
}

variable "vm_password" {
  description = "virtual machine local admin password"
  type        = string
}

variable "vnet_rg_name" {
  description = "virtual network resource group name of the VNET to be attached to the VM"
  type        = string
}

variable "vnet_name" {
  description = "virtual network name of the VNET to be attached to the VM"
  type        = string
}

variable "vnet_private_endpoint_subnet_name" {
  description = "virtual network subnet name of the VNET where private endpoints will be created"
  type        = string
}

variable "vnet_subnet_name" {
  description = "virtual network subnet name of the VNET to be attached to the VM"
  type        = string
}

variable "vnet_appservice_subnet_name" {
  description = "virtual network subnet name of the VNET where app service will be created"
  type        = string
}


variable "dns_resource_group_name" {
  description = "Resource group name where DNS zones are located"
  type        = string
  default     = "your-dns-resource-group-name"
}