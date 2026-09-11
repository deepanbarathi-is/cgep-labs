variable "project_name" {
  type    = string
  default = "cgep-lab"
}
#- GOVERNANCE: objects are still locked and protected by default. The difference is that a caller with the special 
#s3:BypassGovernanceRetention permission can delete/overwrite a locked object early, by explicitly passing --bypass-governance-retention

#- COMPLIANCE: no one can bypass it, ever, for any reason, not even root — the object simply cannot be touched until the retention window passes
#GOVERNANCE is the default lock mode for lab work.
#COMPLIANCE is the lock mode for real evidence.
variable "lock_mode" {
  type        = string
  description = "GOVERNANCE for lab work; COMPLIANCE for real evidence."
  default     = "GOVERNANCE"
  validation {
    condition     = contains(["GOVERNANCE", "COMPLIANCE"], var.lock_mode)
    error_message = "lock_mode must be GOVERNANCE or COMPLIANCE."
  }
}

variable "retention_days" {
  type        = number
  description = "Default retention applied to every uploaded object."
  default     = 1
}