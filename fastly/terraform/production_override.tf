resource "heroku_formation" "production-eu" {
  app      = "${heroku_app.production-eu.name}"
  type     = "web"
  quantity = 2
  size     = "standard-2x"

  provisioner "local-exec" {
    command = "./bin/health-check ${data.heroku_app.production-eu.web_url}"
  }
}

resource "heroku_formation" "production-us" {
  app      = "${heroku_app.production-us.name}"
  type     = "web"
  quantity = 2
  size     = "standard-2x"

  provisioner "local-exec" {
    command = "./bin/health-check ${data.heroku_app.production-us.web_url}"
  }
}

# Build code & release to the app
resource "heroku_build" "production-eu" {
  app = "${heroku_app.production-eu.id}"

  source = {
    # A local directory, changing its contents will
    # force a new build during `terraform apply`
    path = "../../"
  }
}
resource "heroku_build" "production-us" {
  app = "${heroku_app.production-us.id}"

  source = {
    # A local directory, changing its contents will
    # force a new build during `terraform apply`
    path = "../../"
  }
}

resource "fastly_service_v1" "app" {
  domain {
    name = "polyfill.io"
  }

  domain {
    name = "www.polyfill.io"
  }

  domain {
    name = "cdn.polyfill.io"
  }

  domain {
    name = "cdn.polyfills.io"
  }

  domain {
    name = "polyfills.io"
  }

  domain {
    name = "www.polyfills.io"
  }

  domain {
    name = "polyfill.webservices.ft.com"
  }

  backend {
    name                  = "v3_eu"
    address               = "${data.heroku_app.production-eu.name}.herokuapp.com"
    port                  = 443
    healthcheck           = "v3_eu_healthcheck"
    ssl_cert_hostname     = "*.herokuapp.com"
    auto_loadbalance      = false
    connect_timeout       = 5000
    first_byte_timeout    = 120000
    between_bytes_timeout = 120000
    error_threshold       = 0
    shield                = "london_city-uk"
    override_host         = "${data.heroku_app.production-eu.name}.herokuapp.com"
  }

  healthcheck {
    name      = "v3_eu_healthcheck"
    host      = "${data.heroku_app.production-eu.name}.herokuapp.com"
    path      = "/__gtg"
    timeout   = 5000
    threshold = 2
    window    = 5
  }

  backend {
    name                  = "v3_us"
    address               = "${data.heroku_app.production-us.name}.herokuapp.com"
    port                  = 443
    healthcheck           = "v3_us_healthcheck"
    ssl_cert_hostname     = "*.herokuapp.com"
    auto_loadbalance      = false
    connect_timeout       = 5000
    first_byte_timeout    = 120000
    between_bytes_timeout = 120000
    error_threshold       = 0
    shield                = "iad-va-us"
    override_host         = "${data.heroku_app.production-us.name}.herokuapp.com"
  }

  healthcheck {
    name      = "v3_us_healthcheck"
    host      = "${data.heroku_app.production-us.name}.herokuapp.com"
    path      = "/__gtg"
    timeout   = 5000
    threshold = 2
    window    = 5
  }
}


resource "fastly_service_dictionary_items_v1" "items" {
  service_id    = fastly_service_v1.app.id
  dictionary_id = "${ { for dictionary in fastly_service_v1.app.dictionary : dictionary.name => dictionary.dictionary_id }["toppops_config"]}"

  items = {
    datacenters : "LCY,NRT,HAM,BWI,DCA"
    sample_percent : "5"
  }

  lifecycle {
    ignore_changes = [items, ]
  }
}
