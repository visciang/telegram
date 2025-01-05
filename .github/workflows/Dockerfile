# syntax=docker/dockerfile:1-labs
# check=skip=InvalidDefaultArgInFrom

ARG ELIXIR_BASE_IMAGE
ARG APP_BASE_IMAGE


FROM ${ELIXIR_BASE_IMAGE} AS toolchain
WORKDIR "/build"
ARG TOOLCHAIN_PKGS=""
RUN apk add --no-cache git build-base ${TOOLCHAIN_PKGS}
RUN mix local.rebar --force && \
    mix local.hex --force


FROM toolchain AS deps_get
ARG MIX_DEPS_GET_ARGS="--check-locked"
COPY mix.exs mix.lock ./
RUN --mount=type=ssh mix deps.get ${MIX_DEPS_GET_ARGS}


FROM deps_get AS deps_compile
ARG MIX_DEPS_COMPILE_ARGS=""
COPY config* ./config
COPY priv* ./priv
RUN mix deps.compile ${MIX_DEPS_COMPILE_ARGS}


FROM deps_compile AS compile_base
COPY lib ./lib


FROM compile_base AS compile_dev
ARG MIX_COMPILE_ARGS="--warnings-as-errors"
ENV MIX_ENV=dev
RUN mix compile ${MIX_COMPILE_ARGS}
# --
FROM compile_base AS compile_test
ARG MIX_COMPILE_ARGS="--warnings-as-errors"
ENV MIX_ENV=test
RUN mix compile ${MIX_COMPILE_ARGS}
# --
FROM compile_base AS compile_prod
ARG MIX_COMPILE_ARGS="--warnings-as-errors"
ENV MIX_ENV=prod
RUN mix compile ${MIX_COMPILE_ARGS}
# --
FROM compile_dev AS compile


FROM compile_test AS test
ARG MIX_TEST_COMMAND="coveralls.html --warnings-as-errors"
COPY coveralls.json* coveralls.json
COPY test ./test
RUN mix ${MIX_TEST_COMMAND}


FROM compile_test AS format
ARG MIX_FORMAT_ARGS="--check-formatted"
COPY .formatter.exs .
COPY test ./test
RUN mix format ${MIX_FORMAT_ARGS}


FROM deps_compile AS dialyzer_plt
RUN mix dialyzer --plt


FROM compile_dev AS dialyzer
ARG MIX_DIALYZER_ARGS=""
COPY --from=dialyzer_plt /build/_build/plts ./_build/plts
RUN mix dialyzer --no-check ${MIX_DIALYZER_ARGS}


FROM compile_dev AS credo
ARG MIX_CREDO_ARGS="--all --strict"
COPY .credo.exs* .credo.exs
RUN mix credo ${MIX_CREDO_ARGS}


FROM compile_dev AS docs_build
ARG MIX_DOCS_ARGS="--formatter=html"
COPY --parents ./**/*.md ./
RUN mix docs ${MIX_DOCS_ARGS}


FROM scratch AS docs
COPY --from=docs_build /build/doc /doc


FROM compile_prod AS release
ARG RELEASE_NAME=""
COPY rel* ./rel
RUN mix release --path=_release ${RELEASE_NAME}


FROM ${APP_BASE_IMAGE} AS app
ARG APP_NAME
ARG APP_PKGS="libstdc++ ca-certificates ncurses openssl pcre unixodbc zlib"
RUN apk add --no-cache ${APP_PKGS}
COPY --from=release /build/_release /app
RUN ln -s /app/bin/${APP_NAME} /app/bin/app
ENTRYPOINT ["/app/bin/app"]
CMD ["start"]
