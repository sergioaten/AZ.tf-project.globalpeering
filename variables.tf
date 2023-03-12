variable "vmsize" {
    description = "Tamaño de las máquinas virtuales en azure."
}

variable "vmuser" {
    description = "Usuario Administrador de las máquinas virtuales."
}

variable "public-sshkey" {
    description = "Clave pública SSH que se utilizará para hacer login a través de SSH en las máquinas virtuales."
}

variable "path-private-sshkey" {
    description = "PATH del fichero .pem de la clave privada SSH que se utilizará para hacer login a través de SSH en las máquinas virtuales. "
}