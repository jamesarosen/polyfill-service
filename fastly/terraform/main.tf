provider "heroku" {
  version = "~> 2.2"
}

data "heroku_app" "int" {
  name = "origami-polyfill-service-int"
}

resource "heroku_app" "int" {
  name   = "origami-polyfill-service-int"
  region = "eu"

  organization {
    name = "ft-origami"
  }
}

data "heroku_app" "staging-eu" {
  name = "origami-polyfill-service-qa-eu"
}

data "heroku_app" "staging-us" {
  name = "origami-polyfill-service-qa-us"
}

resource "heroku_app" "staging-eu" {
  name   = "origami-polyfill-service-qa-eu"
  region = "eu"

  organization {
    name = "ft-origami"
  }
}

resource "heroku_app" "staging-us" {
  name   = "origami-polyfill-service-qa-us"
  region = "us"

  organization {
    name = "ft-origami"
  }
}

data "heroku_app" "production-eu" {
  name = "origami-polyfill-service-eu"
}

data "heroku_app" "production-us" {
  name = "origami-polyfill-service-us"
}

resource "heroku_app" "production-eu" {
  name   = "origami-polyfill-service-eu"
  region = "eu"

  organization {
    name = "ft-origami"
  }
}

resource "heroku_app" "production-us" {
  name   = "origami-polyfill-service-us"
  region = "us"

  organization {
    name = "ft-origami"
  }
}

resource "heroku_pipeline" "origami-polyfill-service" {
  name = "origami-polyfill-service"
}

resource "heroku_pipeline_coupling" "staging-eu" {
  app      = "${heroku_app.staging-eu.name}"
  pipeline = "${heroku_pipeline.test-app.id}"
  stage    = "staging"
}

resource "heroku_pipeline_coupling" "stagingp-us" {
  app      = "${heroku_app.stagingp-us.name}"
  pipeline = "${heroku_pipeline.test-app.id}"
  stage    = "staging"
}

resource "heroku_pipeline_coupling" "production-eu" {
  app      = "${heroku_app.production-eu.name}"
  pipeline = "${heroku_pipeline.origami-polyfill-service.id}"
  stage    = "production"
}

resource "heroku_pipeline_coupling" "production-us" {
  app      = "${heroku_app.production-us.name}"
  pipeline = "${heroku_pipeline.origami-polyfill-service.id}"
  stage    = "production"
}

provider "fastly" {
  version = "0.11.1"
}

variable "domain" {
  default = "polyfill.io"
}

variable "name" {
  default = "Origami Polyfill Service"
}

output "service_id" {
  value = ["${fastly_service_v1.app.id}"]
}

resource "fastly_service_v1" "app" {
  name = "${var.name}"

  force_destroy = false

  domain {
    name = "${var.domain}"
  }

  vcl {
    name    = "main.vcl"
    content = "${file("${path.module}/../vcl/main.vcl")}"
    main    = true
  }

  vcl {
    name    = "polyfill-service.vcl"
    content = "${file("${path.module}/../vcl/polyfill-service.vcl")}"
  }

  vcl {
    name    = "normalise-user-agent-3-25-1.vcl"
    content = "${file("${path.module}/../vcl/normalise-user-agent-3-25-1.vcl")}"
  }

  vcl {
    name    = "normalise-user-agent.vcl"
    content = "${file("${path.module}/../../node_modules/@financial-times/polyfill-useragent-normaliser/lib/normalise-user-agent.vcl")}"
  }

  vcl {
    name    = "fastly-boilerplate-begin.vcl"
    content = "${file("${path.module}/../vcl/fastly-boilerplate-begin.vcl")}"
  }

  vcl {
    name    = "fastly-boilerplate-end.vcl"
    content = "${file("${path.module}/../vcl/fastly-boilerplate-end.vcl")}"
  }

  vcl {
    name    = "breadcrumbs.vcl"
    content = "${file("${path.module}/../vcl/breadcrumbs.vcl")}"
  }

  vcl {
    name    = "redirects.vcl"
    content = "${file("${path.module}/../vcl/redirects.vcl")}"
  }

  vcl {
    name    = "synthetic-responses.vcl"
    content = "${file("${path.module}/../vcl/synthetic-responses.vcl")}"
  }

  vcl {
    name    = "top_pops.vcl"
    content = "${file("${path.module}/../vcl/top_pops.vcl")}"
  }

  dictionary {
    name = "toppops_config"
  }
}

resource "fastly_service_dictionary_items_v1" "items" {
  service_id    = "${fastly_service_v1.app.id}"
  dictionary_id = "${ { for dictionary in fastly_service_v1.app.dictionary : dictionary.name => dictionary.dictionary_id }["toppops_config"]}"

  items = {
  }

  lifecycle {
    ignore_changes = [items, ]
  }
}
