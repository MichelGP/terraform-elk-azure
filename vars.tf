variable "nsgip" {
 description = "Workstation external IP to allow connections to JB, Kibana, Grafana"
 default = "37.17.220.27"
 #default = "*"
}

variable "ssh_user" {
 default = "michel"
}

variable "ssh_pubkey_location" {
 default = "~/.ssh/dummychefsolokey.pub"
}

variable "ssh_privkey_location" {
 default = "~/.ssh/dummychefsolokey"
}

variable "subscription_id" {
    default = ""
}

variable "client_id" {
    default = ""
}

variable "client_secret" {
    default = ""
}

variable "tenant_id" {
    default = ""
}
