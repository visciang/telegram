#!/usr/bin/env bash

set -eo pipefail

BUILDX_BUILDER_NAME="test-builder"
BUILDKIT_VERSION="v0.18.2"

function docker_buildx_setup {
    docker buildx create --name=$BUILDX_BUILDER_NAME --driver=docker-container --driver-opt=image=moby/buildkit:$BUILDKIT_VERSION
}

function docker_buildx_teardown {
    docker buildx rm $BUILDX_BUILDER_NAME
}

function docker_buildx_prune {
    docker buildx prune --all --force --builder $BUILDX_BUILDER_NAME
}

function _docker_buildx_build_opts {
    TARGET=$1

    APP_BASE_IMAGE="alpine:3.20.3"
    ELIXIR_BASE_IMAGE="hexpm/elixir:1.18.1-erlang-27.2-alpine-3.20.3"

    if [ "$GITHUB_ACTIONS" == "true" ]; then
        GIT_SHA="$GITHUB_SHA"
        GIT_BRANCH="$GITHUB_REF_NAME"

        CACHE_OPTS="--cache-to \"type=gha,mode=max\" --cache-from \"type=gha\""
    else
        GIT_SHA="$(git rev-parse --short HEAD)"
        GIT_BRANCH="$(git branch --show-current)"

        BUILD_CACHE_S3_MANIFEST_NAME_1="$TARGET-$GIT_SHA"
        BUILD_CACHE_S3_MANIFEST_NAME_2="$TARGET-$GIT_BRANCH"
        BUILD_CACHE_S3_ENDPOINT_URL="http://192.168.1.12:9000"
        BUILD_CACHE_S3_BUCKET="docker"
        BUILD_CACHE_S3_ACCESS_KEY_ID="dockerkey"
        BUILD_CACHE_S3_SECRET_ACCESS_KEY="dockerkey"

        CACHE_OPTS="--cache-to \"type=s3,mode=max,region=eu-west-1,bucket=$BUILD_CACHE_S3_BUCKET,name=$BUILD_CACHE_S3_MANIFEST_NAME_1,endpoint_url=$BUILD_CACHE_S3_ENDPOINT_URL,access_key_id=$BUILD_CACHE_S3_ACCESS_KEY_ID,secret_access_key=$BUILD_CACHE_S3_SECRET_ACCESS_KEY\" --cache-to \"type=s3,mode=max,region=eu-west-1,bucket=$BUILD_CACHE_S3_BUCKET,name=$BUILD_CACHE_S3_MANIFEST_NAME_2,endpoint_url=$BUILD_CACHE_S3_ENDPOINT_URL,access_key_id=$BUILD_CACHE_S3_ACCESS_KEY_ID,secret_access_key=$BUILD_CACHE_S3_SECRET_ACCESS_KEY\" --cache-from \"type=s3,region=eu-west-1,bucket=$BUILD_CACHE_S3_BUCKET,name=$BUILD_CACHE_S3_MANIFEST_NAME_1,endpoint_url=$BUILD_CACHE_S3_ENDPOINT_URL,access_key_id=$BUILD_CACHE_S3_ACCESS_KEY_ID,secret_access_key=$BUILD_CACHE_S3_SECRET_ACCESS_KEY\" --cache-from \"type=s3,region=eu-west-1,bucket=$BUILD_CACHE_S3_BUCKET,name=$BUILD_CACHE_S3_MANIFEST_NAME_2,endpoint_url=$BUILD_CACHE_S3_ENDPOINT_URL,access_key_id=$BUILD_CACHE_S3_ACCESS_KEY_ID,secret_access_key=$BUILD_CACHE_S3_SECRET_ACCESS_KEY\""
    fi

    echo "--target $TARGET --builder $BUILDX_BUILDER_NAME --build-arg ELIXIR_BASE_IMAGE="$ELIXIR_BASE_IMAGE" --build-arg APP_BASE_IMAGE="$APP_BASE_IMAGE" --file .github/workflows/Dockerfile $CACHE_OPTS"
}

function docker_pipeline {
    for TARGET in "$@"; do
        OPTS="$(_docker_buildx_build_opts "$TARGET")"

        case "$TARGET" in
            "compile")
                eval docker buildx build $OPTS .
                ;;
            "format")
                eval docker buildx build $OPTS .
                ;;
            "test")
                eval docker buildx build $OPTS .
                ;;
            "dialyzer")
                eval docker buildx build $OPTS .
                ;;
            "credo")
                eval docker buildx build $OPTS .
                ;;
            "docs")
                eval docker buildx build $OPTS --output "type=local,dest=." .
                ;;
            "release")
                eval docker buildx build $OPTS --build-arg RELEASE_NAME="$RELEASE_NAME" .
                ;;
            "app")
                eval docker buildx build $OPTS --build-arg APP_NAME="$APP_NAME" --build-arg RELEASE_NAME="$RELEASE_NAME" .
                ;;
            "all")
                docker_pipeline compile
                docker_pipeline format
                docker_pipeline test
                docker_pipeline dialyzer
                docker_pipeline credo
                docker_pipeline docs
                ;;
            *)
                echo "unknown target '$TARGET'"
                return 1;;
        esac
    done
}
