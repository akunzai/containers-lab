ui = true
disable_mlock = true

storage "file" {
  path = "/vault/file"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}

# Allow API access from outside the container
api_addr = "http://0.0.0.0:8200"

# Default and max token TTL
default_lease_ttl = "168h"
max_lease_ttl = "720h"
