ui = true
disable_mlock = true

storage "file" {
  path = "/vault/file"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

# 允許從容器外訪問 API
api_addr = "http://0.0.0.0:8200"

# 預設 token TTL
default_lease_ttl = "168h"
max_lease_ttl = "720h"
