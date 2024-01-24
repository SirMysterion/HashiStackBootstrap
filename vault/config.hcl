api_addr = "http://[::1]:8200"
cluster_addr = "http://[::1]:8201"

ui = true

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = "true"
}

listener "tcp" {
  address     = "[::1]:8200"
  tls_disable = "true"
}

// listener "tcp" {
//   address     = "<Public IP>:8200"
//   tls_disable = "true"
// }

// storage "file" {
//   path = "./data"
// }

# Consul Registration requires HA Compatable Storage
storage "raft" {
  path = "./data"
  node_id = "raft_node_1"
}

service_registration "consul" {
  // address = "127.0.0.1:8500"
  address = "[::1]:8500"
  token   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
