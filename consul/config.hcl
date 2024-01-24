enable_debug = true

server = true
bootstrap_expect = 1
connect = {
   enabled = true
}

client_addr = "::"
bind_addr = "::1"

ports = {
   grpc = 8502
}

// data_dir = "./data"

ui_config {
  enabled = true
}

acl = {
   enabled = true 
   default_policy = "deny" 
   enable_token_persistence = true 
   // tokens = {
   //    default = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"   # bootstrap
   //    dns     = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"   # DNS Token
   // }
}
