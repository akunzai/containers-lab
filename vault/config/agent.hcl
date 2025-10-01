pid_file = "/tmp/vault-agent.pid"

vault {
  address = "${env("VAULT_ADDR")}"
  retry { num_retries = 12 }
}

auto_auth {
  method {
    type = "approle"
    config = {
      role_id_file_path   = "/vault/approle/role-id"
      secret_id_file_path = "/vault/approle/secret-id"
      remove_secret_id_file_after_reading = false
    }
  }

  sink {
    type = "file"
    config = {
      path = "/tmp/vault-token"
    }
  }
}

listener "unix" {
  address = "/tmp/vault-agent.sock"
  tls_disable = true
}

cache {
  use_auto_auth_token = true
}

template {
  source              = "/vault/config/templates/render-secrets.sh.ctmpl"
  destination         = "/tmp/render-secrets.sh"
  perms               = "0500"
  create_dest_dirs    = true
  command             = "/bin/sh /tmp/render-secrets.sh"
  error_on_missing_key = false
}