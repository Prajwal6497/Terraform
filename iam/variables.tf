variable "region" {
  default = "ap-south-1"
}

variable "pgp_key" {
 description = "Either a base-64 encoded PGP public key, or a keybase username in the form keybase:username. Used to encrypt the password and the access key on output to the console."
 default     = ""
}