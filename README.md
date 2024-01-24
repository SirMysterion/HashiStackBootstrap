# HashiStackBootstrap

Not all of these are sane defaults but enought to get a basic setup started that is not -Dev flag.

## Start Services
Recomended to run each in their own terminal

```
cd vault
vault server -config=config.hcl
```

```
cd consul
consul agent -config-file config.hcl -data-dir=$PWD/data
```

```
cd nomad
sudo nomad agent -config=config.hcl -data-dir=$PWD/data
```

---
# Start a New Shell

## VAULT START
```
export VAULT_ADDR='http://localhost:8200'
vault operator init -key-shares=5 -key-threshold=3 | tee vault.bootstrap
export VAULT_TOKEN=$(cat vault.bootstrap | grep "Initial Root Token" | awk '{print $4}')
vault operator unseal $(cat vault.bootstrap | grep "Unseal Key 1" | awk '{print $4}')
vault operator unseal $(cat vault.bootstrap | grep "Unseal Key 2" | awk '{print $4}')
vault operator unseal $(cat vault.bootstrap | grep "Unseal Key 3" | awk '{print $4}')
```

## CONSUL START

```
export CONSUL_HTTP_ADDR=localhost:8500
consul acl bootstrap | tee consul.bootstrap
export CONSUL_HTTP_TOKEN=$(cat consul.bootstrap | grep SecretID | awk '{print $2}')

vault secrets enable consul
vault write consul/config/access address=${CONSUL_HTTP_ADDR} token=${CONSUL_HTTP_TOKEN}
``````

## Consul/Vault ACL Token (Consul Agents?)
```
# consul acl policy create -name consul-servers -rules @server_policy.hcl
# vault write consul/roles/consul-server-role policies=consul-servers
# vault read consul/creds/consul-server-role | tee consul-server.token
# export CONSUL_SERVER_TOKEN=$(cat consul-server.token | grep token | awk '{print $2}')
# consul acl set-agent-token agent $(cat consul-server.token | grep token | awk '{print $2}')
```
Or, Cause I want to use a sledge hammer
Set consul configuration as Default token

```
consul acl set-agent-token agent $(cat consul.bootstrap | grep SecretID | awk '{print $2}') 
```

## Vault/Consul Service Register

```
# consul acl policy create -name vault-servers -rules @vault-servers-policy.hcl
# vault write consul/roles/vault-servers-role policies=vault-servers
# vault read consul/creds/vault-servers-role | tee vault-server.token
```
Or, Cause I want to use a sledge hammer

```
sed -i "s/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/${CONSUL_HTTP_TOKEN}/" vault/config.hcl
```

Restart Vault
```
vault operator unseal $(cat vault.bootstrap | grep "Unseal Key 1" | awk '{print $4}')
vault operator unseal $(cat vault.bootstrap | grep "Unseal Key 2" | awk '{print $4}')
vault operator unseal $(cat vault.bootstrap | grep "Unseal Key 3" | awk '{print $4}')
```

## NOMAD START
```
export NOMAD_HTTP_ADDR=localhost:4646
nomad acl bootstrap | tee nomad.bootstrap
export NOMAD_TOKEN=$(cat nomad.bootstrap | grep "Secret ID" | awk '{print $4}')
vault secrets enable nomad
vault write nomad/config/access address=${NOMAD_HTTP_ADDR} token=$NOMAD_TOKEN
```

# Nomad/Consul Service Register
```
# consul acl policy create -name "nomad-server" -description "Nomad Server Policy" -rules @nomad-server-policy.hcl
# consul acl policy create -name "nomad-client" -description "Nomad Client Policy" -rules @nomad-client-policy.hcl
# consul acl token create -description "Nomad Demo Agent Token" -policy-name "nomad-server" -policy-name "nomad-client" | tee nomad-agent.token
```

Or, Cause I want to use a sledge hammer

```sed -i "s/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/${CONSUL_HTTP_TOKEN}/" nomad/config.hcl```

Update Nomad config Consul Token Section and restart

## Enable Consul DNS Lookups
```
consul acl token create -description "dns-token" -templated-policy "builtin/dns" | tee consul-dns.token
consul acl set-agent-token dns $(cat consul-dns.token | grep SecretID | awk '{print $2}')
```

## Nomad/Consul Workloads
Read: [Consul ACL with Nomad Workload Identities](https://developer.hashicorp.com/nomad/tutorials/integrate-consul/consul-acl)

```
consul acl auth-method create -name 'nomad-workloads' -type 'jwt' -description 'JWT auth method for Nomad services and workloads' -config '@nomad/consul-auth-method-nomad-workloads.json'
consul acl binding-rule create -method 'nomad-workloads' -description 'Binding rule for services registered from Nomad' -bind-type 'service' -bind-name '${value.nomad_service}' -selector '"nomad_service" in value'
consul acl binding-rule create -method 'nomad-workloads' -description 'Binding rule for Nomad tasks' -bind-type 'role' -bind-name 'nomad-tasks-${value.nomad_namespace}' -selector '"nomad_service" not in value'
consul acl policy create -name 'nomad-tasks' -description 'ACL policy used by Nomad tasks' -rules '@consul/consul-policy-nomad-tasks.hcl'
consul acl role create -name 'nomad-tasks-default' -description 'ACL role for Nomad tasks in the default Nomad namespace' -policy-name 'nomad-tasks'
```

## Nomad/Vault Workloads
Read: [Vault ACL with Nomad Workload Identities](https://developer.hashicorp.com/nomad/tutorials/integrate-vault/vault-acl)

```
vault auth enable -path 'jwt-nomad' 'jwt'
vault write auth/jwt-nomad/config '@nomad/vault-auth-method-jwt-nomad.json'
vault write auth/jwt-nomad/role/nomad-workloads '@nomad/vault-role-nomad-workloads.json'
export JWT_NOMAD=$(vault auth list | grep auth_jwt_ | awk '{print $3}')
sed -i "s/auth_jwt_xxxxxxxx/${JWT_NOMAD}/g" nomad/vault-policy-nomad-workloads.hcl
vault policy write 'nomad-workloads' 'nomad/vault-policy-nomad-workloads.hcl'
vault secrets enable -version '2' 'kv'
```





######
## Test Nomad/Consul Workloads
```nomad job run nomad/httpd.nomad.hcl```

## Test Nomad/Vault Workloads
```
vault kv put -mount 'kv' 'default/mongo/config' 'root_password=secret-password'
nomad job run nomad/mongo.nomad.hcl
```

Test if Authentication works (ie. using Vault Creds)

```nomad alloc exec "$(nomad job allocs -t '{{with (index . 0)}}{{.ID}}{{end}}' 'mongo')" mongosh --username 'root' --password 'secret-password' --eval 'db.runCommand({connectionStatus : 1})' --quiet```

Test Consul DNS Lookup Service
```dig +short @localhost -p 8600 mongo.service.dc1.consul```

Should return 127.0.0.1