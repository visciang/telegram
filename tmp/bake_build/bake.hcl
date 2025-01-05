variable "GIT_SHA" { default = "$GIT_SHA" }
variable "GIT_BRANCH" { default = "$GIT_BRANCH" }

variable "APP_NAME" { default = "$APP_NAME" }
variable "APP_PKGS" { default = "libstdc++ ca-certificates ncurses openssl pcre unixodbc zlib" }
variable "APP_TAG" { default = "${APP_NAME}:latest" }
variable "APP_BASE_IMAGE" { default = "alpine:3.20.3" }
variable "ELIXIR_BASE_IMAGE" { default = "hexpm/elixir:1.18.1-erlang-27.2-alpine-3.20.3" }
variable "MIX_COMPILE_ARGS" { default = "--warnings-as-errors" }
variable "MIX_DEPS_COMPILE_ARGS" { default = "" }
variable "MIX_DEPS_GET_ARGS" { default = "--check-locked" }
variable "MIX_DIALYZER_ARGS" { default = "" }
variable "MIX_DOCS_ARGS" { default = "--formatter=html" }
variable "MIX_FORMAT_ARGS" { default = "--check-formatted" }
variable "MIX_TEST_COMMAND" { default = "coveralls.html --warnings-as-errors" }
variable "RELEASE_NAME" { default = "" }
variable "TOOLCHAIN_PKGS" { default = "" }
variable "WORKDIR" { default = "/build" }

variable "DOCKER_CACHE_S3_ENDPOINT_URL" { default = "http://192.168.1.12:9000" }
variable "DOCKER_CACHE_S3_ACCESS_KEY_ID" { default = "dockerkey" }
variable "DOCKER_CACHE_S3_SECRET_ACCESS_KEY" { default = "dockerkey" }

variable "CACHE_FROM" { default = "type=s3,region=eu-west-1,bucket=docker,endpoint_url=${DOCKER_CACHE_S3_ENDPOINT_URL},access_key_id=${DOCKER_CACHE_S3_ACCESS_KEY_ID},secret_access_key=${DOCKER_CACHE_S3_SECRET_ACCESS_KEY}" }
variable "CACHE_TO" { default = "type=s3,mode=max,region=eu-west-1,bucket=docker,endpoint_url=${DOCKER_CACHE_S3_ENDPOINT_URL},access_key_id=${DOCKER_CACHE_S3_ACCESS_KEY_ID},secret_access_key=${DOCKER_CACHE_S3_SECRET_ACCESS_KEY}" }

group "all" {
  targets = ["test", "format", "dialyzer", "docs"]
}

target "_common" {
  args = {
    # enable experimental `COPY --parents`
    BUILDKIT_SYNTAX = "docker/dockerfile:1-labs"
  }
}

target "toolchain" {
  inherits          = ["_common"]
  dockerfile-inline = <<EOT
    FROM ${ELIXIR_BASE_IMAGE}
    WORKDIR "${WORKDIR}"
    RUN apk add --no-cache git build-base ${TOOLCHAIN_PKGS}
    RUN mix local.rebar --force && \
        mix local.hex --force
  EOT
  cache-from = [
    "${CACHE_FROM},name=toolchain-${GIT_SHA}",
    "${CACHE_FROM},name=toolchain-${GIT_BRANCH}"
  ]
  cache-to = [
    "${CACHE_TO},name=toolchain-${GIT_SHA}",
    "${CACHE_TO},name=toolchain-${GIT_BRANCH}"
  ]
}

target "deps_get" {
  inherits = ["_common"]
  contexts = {
    toolchain = "target:toolchain"
  }
  dockerfile-inline = <<EOT
    FROM toolchain
    COPY mix.exs mix.lock ./
    RUN --mount=type=ssh mix deps.get ${MIX_DEPS_GET_ARGS}
  EOT
  cache-from = [
    "${CACHE_FROM},name=deps_get-${GIT_SHA}",
    "${CACHE_FROM},name=deps_get-${GIT_BRANCH}"
  ]
  cache-to = [
    "${CACHE_TO},name=deps_get-${GIT_SHA}",
    "${CACHE_TO},name=deps_get-${GIT_BRANCH}"
  ]
}

target "deps_compile" {
  inherits = ["_common"]
  contexts = {
    deps_get = "target:deps_get"
  }
  dockerfile-inline = <<EOT
    FROM deps_get
    COPY config* ./config
    COPY priv* ./priv
    RUN mix deps.compile ${MIX_DEPS_COMPILE_ARGS}
  EOT
  cache-from = [
    "${CACHE_FROM},name=deps_compile-${GIT_SHA}",
    "${CACHE_FROM},name=deps_compile-${GIT_BRANCH}"
  ]
  cache-to = [
    "${CACHE_TO},name=deps_compile-${GIT_SHA}",
    "${CACHE_TO},name=deps_compile-${GIT_BRANCH}"
  ]
}

target "compile" {
  name     = "compile-${MIX_ENV}"
  inherits = ["_common"]
  contexts = {
    deps_compile = "target:deps_compile"
  }
  matrix = {
    MIX_ENV = ["dev", "test", "prod"]
  }
  dockerfile-inline = <<EOT
    FROM deps_compile
    COPY lib ./lib
    ENV MIX_ENV=${MIX_ENV}
    RUN mix compile ${MIX_COMPILE_ARGS}
  EOT
  cache-from = [
    "${CACHE_FROM},name=compile-${MIX_ENV}-${GIT_SHA}",
    "${CACHE_FROM},name=compile-${MIX_ENV}-${GIT_BRANCH}"
  ]
  cache-to = [
    "${CACHE_TO},name=compile-${MIX_ENV}-${GIT_SHA}",
    "${CACHE_TO},name=compile-${MIX_ENV}-${GIT_BRANCH}"
  ]
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
  cache-from = [
    "${CACHE_FROM},name=test-${GIT_SHA}",
    "${CACHE_FROM},name=test-${GIT_BRANCH}"
  ]
  cache-to = [
    "${CACHE_TO},name=test-${GIT_SHA}",
    "${CACHE_TO},name=test-${GIT_BRANCH}"
  ]
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
  cache-from = [
    "${CACHE_FROM},name=format-${GIT_SHA}",
    "${CACHE_FROM},name=format-${GIT_BRANCH}"
  ]
  cache-to = [
    "${CACHE_TO},name=format-${GIT_SHA}",
    "${CACHE_TO},name=format-${GIT_BRANCH}"
  ]
}

target "dialyzer_plt" {
  inherits = ["_common"]
  contexts = {
    deps_compile = "target:deps_compile"
  }
  dockerfile-inline = <<EOT
    FROM deps_compile
    RUN mix dialyzer --plt
  EOT
  cache-from = [
    "${CACHE_FROM},name=dialyzer_plt-${GIT_SHA}",
    "${CACHE_FROM},name=dialyzer_plt-${GIT_BRANCH}"
  ]
  cache-to = [
    "${CACHE_TO},name=dialyzer_plt-${GIT_SHA}",
    "${CACHE_TO},name=dialyzer_plt-${GIT_BRANCH}"
  ]
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
  cache-from = [
    "${CACHE_FROM},name=dialyzer-${GIT_SHA}",
    "${CACHE_FROM},name=dialyzer-${GIT_BRANCH}"
  ]
  cache-to = [
    "${CACHE_TO},name=dialyzer-${GIT_SHA}",
    "${CACHE_TO},name=dialyzer-${GIT_BRANCH}"
  ]
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
  cache-from = [
    "${CACHE_FROM},name=docs_build-${GIT_SHA}",
    "${CACHE_FROM},name=docs_build-${GIT_BRANCH}"
  ]
  cache-to = [
    "${CACHE_TO},name=docs_build-${GIT_SHA}",
    "${CACHE_TO},name=docs_build-${GIT_BRANCH}"
  ]
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
  cache-from = [
    "${CACHE_FROM},name=docs-${GIT_SHA}",
    "${CACHE_FROM},name=docs-${GIT_BRANCH}"
  ]
  cache-to = [
    "${CACHE_TO},name=docs-${GIT_SHA}",
    "${CACHE_TO},name=docs-${GIT_BRANCH}"
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
  cache-from = [
    "${CACHE_FROM},name=release-${GIT_SHA}",
    "${CACHE_FROM},name=release-${GIT_BRANCH}"
  ]
  cache-to = [
    "${CACHE_TO},name=release-${GIT_SHA}",
    "${CACHE_TO},name=release-${GIT_BRANCH}"
  ]
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
  cache-from = [
    "${CACHE_FROM},name=app-${GIT_SHA}",
    "${CACHE_FROM},name=app-${GIT_BRANCH}"
  ]
  cache-to = [
    "${CACHE_TO},name=app-${GIT_SHA}",
    "${CACHE_TO},name=app-${GIT_BRANCH}"
  ]
}