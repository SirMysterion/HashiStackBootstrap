// data_dir = "/home/user/hashistack/nomad/data"

bind_addr = "::"

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = true
  network_interface = "lo"
}

acl {
  enabled = true
}

vault {
  enabled = true
  address = "http://[::1]:8200"

  default_identity {
    aud = ["vault.io"]
    ttl = "1h"
  }
}

consul {
  address = "[::1]:8500"
  token   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  

  service_identity {
    aud = ["consul.io"]
    ttl = "1h"
  }

  task_identity {
    aud = ["consul.io"]
    ttl = "1h"
  }
}

plugin "docker" {
  config {
    allow_privileged = true
    volumes {
      enabled      = true
    }
  }
}

