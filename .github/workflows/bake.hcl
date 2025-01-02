variable "APP_NAME" { default = "$APP_NAME" }
variable "APP_PKGS" { default = "libstdc++ ca-certificates ncurses openssl pcre unixodbc zlib" }
variable "APP_TAG" { default = "${APP_NAME}:latest" }
variable "APP_BASE_IMAGE" { default = "alpine:3.20.3" }
variable "ELIXIR_BASE_VERSION" { default = "hexpm/elixir:1.18.1-erlang-27.2-alpine-3.20.3" }
variable "MIX_COMPILE_ARGS" { default = "--warnings-as-errors" }
variable "MIX_DEPS_COMPILE_ARGS" { default = "" }
variable "MIX_DEPS_GET_ARGS" { default = "--check-locked" }
variable "MIX_DIALYZER_ARGS" { default = "" }
variable "MIX_DOCS_ARGS" { default = "--formatter=html" }
variable "MIX_ENV" { default = "dev" }
variable "MIX_FORMAT_ARGS" { default = "--check-formatted" }
variable "MIX_TEST_COMMAND" { default = "coveralls.html --warnings-as-errors" }
variable "RELEASE_NAME" { default = "" }
variable "TOOLCHAIN_PKGS" { default = "" }

variable "DOCKER_CACHE_S3_ENDPOINT_URL" { default = "http://192.168.1.12:9000" }
variable "DOCKER_CACHE_S3_ACCESS_KEY_ID" { default = "dockerkey" }
variable "DOCKER_CACHE_S3_SECRET_ACCESS_KEY" { default = "dockerkey" }

variable "WORKDIR" { default = "/build" }

group "all" {
  targets = ["test", "format", "dialyzer", "docs"]
}

target "_common" {
  args = {
    # enable experimental `COPY --parents`
    BUILDKIT_SYNTAX = "docker/dockerfile:1-labs"
  }
  cache-from = [
    "type=gha"
    # "type=s3,region=eu-west-1,bucket=docker,endpoint_url=${DOCKER_CACHE_S3_ENDPOINT_URL},access_key_id=${DOCKER_CACHE_S3_ACCESS_KEY_ID},secret_access_key=${DOCKER_CACHE_S3_SECRET_ACCESS_KEY}"
  ]
  cache-to = [
    "type=gha,mode=max"
    # "type=s3,mode=max,region=eu-west-1,bucket=docker,endpoint_url=${DOCKER_CACHE_S3_ENDPOINT_URL},access_key_id=${DOCKER_CACHE_S3_ACCESS_KEY_ID},secret_access_key=${DOCKER_CACHE_S3_SECRET_ACCESS_KEY}"
  ]
}

target "toolchain" {
  inherits          = ["_common"]
  dockerfile-inline = <<EOT
    FROM ${ELIXIR_BASE_VERSION}
    WORKDIR "${WORKDIR}"
    RUN apk add --no-cache git build-base ${TOOLCHAIN_PKGS}
    RUN mix local.rebar --force && \
        mix local.hex --force
  EOT
}

target "deps_src" {
  inherits = ["_common"]
  contexts = {
    toolchain = "target:toolchain"
  }
  dockerfile-inline = <<EOT
    FROM toolchain
    COPY mix.exs mix.lock ./
    RUN --mount=type=ssh mix deps.get ${MIX_DEPS_GET_ARGS}
  EOT
}

target "deps" {
  name     = "deps-${mix_env}"
  inherits = ["_common"]
  contexts = {
    deps_src = "target:deps_src"
  }
  matrix = {
    mix_env = ["dev", "test", "prod"]
  }
  dockerfile-inline = <<EOT
    FROM deps_src
    ENV MIX_ENV=${mix_env}
    COPY config* ./config
    COPY priv* ./priv
    RUN mix deps.compile ${MIX_DEPS_COMPILE_ARGS}
  EOT
}

target "compile" {
  name     = "compile-${mix_env}"
  inherits = ["_common"]
  contexts = {
    deps = "target:deps-${mix_env}"
  }
  matrix = {
    mix_env = ["dev", "test", "prod"]
  }
  dockerfile-inline = <<EOT
    FROM deps
    COPY lib ./lib
    RUN mix compile ${MIX_COMPILE_ARGS}
  EOT
}

target "test" {
  inherits = ["_common"]
  contexts = {
    compile = "target:compile-test"
  }
  dockerfile-inline = <<EOT
    FROM compile
    COPY test ./test
    RUN mix ${MIX_TEST_COMMAND}
  EOT
}

target "format" {
  inherits = ["_common"]
  contexts = {
    compile = "target:compile-test"
  }
  dockerfile-inline = <<EOT
    FROM compile
    COPY .formatter.exs .
    COPY test ./test
    RUN mix format ${MIX_FORMAT_ARGS}
  EOT
}

target "dialyzer_plt" {
  inherits = ["_common"]
  contexts = {
    deps = "target:deps-dev"
  }
  dockerfile-inline = <<EOT
    FROM deps
    RUN mix dialyzer --plt
  EOT
}

target "dialyzer" {
  inherits = ["_common"]
  contexts = {
    compile      = "target:compile-dev"
    dialyzer_plt = "target:dialyzer_plt"
  }
  dockerfile-inline = <<EOT
    FROM compile
    COPY --from=dialyzer_plt /${WORKDIR}/_build/plts ./_build/plts
    RUN mix dialyzer --no-check ${MIX_DIALYZER_ARGS}
  EOT
}

target "docs_build" {
  inherits = ["_common"]
  contexts = {
    compile = "target:compile-dev"
  }
  dockerfile-inline = <<EOT
    FROM compile
    COPY --parents ./**/*.md ./
    RUN mix docs ${MIX_DOCS_ARGS}
  EOT
}

target "docs" {
  inherits = ["_common"]
  contexts = {
    docs_build = "target:docs_build"
  }
  dockerfile-inline = <<EOT
    FROM scratch
    COPY --from=docs_build ${WORKDIR}/doc /doc
  EOT
  output = [
    "type=local,dest=./output"
  ]
}

target "release" {
  inherits = ["_common"]
  contexts = {
    compile = "target:compile-prod"
  }
  dockerfile-inline = <<EOT
    FROM compile
    COPY rel* ./rel
    RUN mix release --path=_release ${RELEASE_NAME}
  EOT
}

target "app" {
  inherits = ["_common"]
  contexts = {
    release = "target:release"
  }
  dockerfile-inline = <<EOT
    FROM ${APP_BASE_IMAGE}
    RUN apk add --no-cache ${APP_PKGS}
    COPY --from=release ${WORKDIR}/_release /app
    ENTRYPOINT ["/app/bin/${APP_NAME}"]
    CMD ["start"]
  EOT
  tags = [
    "${APP_TAG}"
  ]
}