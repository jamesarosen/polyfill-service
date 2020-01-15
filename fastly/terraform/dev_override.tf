resource "heroku_formation" "int" {
  app      = "${heroku_app.int.name}"
  type     = "web"
  quantity = 2
  size     = "standard-2x"

  provisioner "local-exec" {
    command = "./bin/health-check ${data.heroku_app.int.web_url}"
  }
}

# Build code & release to the app
resource "heroku_build" "int" {
  app = "${heroku_app.int.id}"

  source = {
    # A local directory, changing its contents will
    # force a new build during `terraform apply`
    path = "../../"
  }
}

resource "fastly_service_v1" "app" {
  domain {
    name = "origami-polyfill-service-dev.in.ft.com"
  }

  backend {
    name                  = "v3_eu"
    address               = "${data.heroku_app.int.name}.herokuapp.com"
    port                  = 443
    healthcheck           = "v3_eu_healthcheck"
    ssl_cert_hostname     = "*.herokuapp.com"
    auto_loadbalance      = false
    connect_timeout       = 5000
    first_byte_timeout    = 120000
    between_bytes_timeout = 120000
    error_threshold       = 0
    shield                = "london_city-uk"
    override_host         = "${data.heroku_app.int.name}.herokuapp.com"
  }

  healthcheck {
    name      = "v3_eu_healthcheck"
    host      = "${data.heroku_app.int.name}.herokuapp.com"
    path      = "/__gtg"
    timeout   = 5000
    threshold = 2
    window    = 5
  }

  backend {
    name                  = "v3_us"
    address               = "${data.heroku_app.int.name}.herokuapp.com"
    port                  = 443
    healthcheck           = "v3_us_healthcheck"
    ssl_cert_hostname     = "*.herokuapp.com"
    auto_loadbalance      = false
    connect_timeout       = 5000
    first_byte_timeout    = 120000
    between_bytes_timeout = 120000
    error_threshold       = 0
    shield                = "iad-va-us"
    override_host         = "${data.heroku_app.int.name}.herokuapp.com"
  }

  healthcheck {
    name      = "v3_us_healthcheck"
    host      = "${data.heroku_app.int.name}.herokuapp.com"
    path      = "/__gtg"
    timeout   = 5000
    threshold = 2
    window    = 5
  }
}
