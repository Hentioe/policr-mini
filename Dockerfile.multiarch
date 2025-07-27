# Use the Elixir image as the build base
FROM hentioe/elixir:1.18.4-otp-28-nojit-alpine AS build-base
WORKDIR /src
ENV MIX_ENV=prod
RUN set -xe \
    && if [ "$TARGETARCH" = "arm64" ]; then \
    # Avoid QEMU/arm64 build failed. \
    export ERL_FLAGS="+JMsingle true"; \
    fi \
    && apk add --no-cache git

# Compile the Elixir code
FROM build-base AS compile
COPY . /src/
RUN set -xe \
    && mix deps.get \
    && mix compile

# Use Node.js build the frontend
FROM node:22 AS assets-build
WORKDIR /src
COPY --from=compile /src/ /src/
RUN set -xe \
    && npm install --location=global pnpm@10 \
    # && pnpm --prefix assets install \
    # && pnpm --prefix assets run deploy \
    # && pnpm --prefix webapps install \
    # && pnpm --prefix webapps build \
    && pnpm --prefix admin install \
    && pnpm --prefix admin run build \
    && pnpm --prefix console install \
    && pnpm --prefix console run build

# Release the application
FROM compile AS release
COPY --from=assets-build /src/ /src/
RUN set -xe \
    && mix phx.digest \
    && mix release

# Use the Alpine base image for the final package
FROM alpine:3.22
ARG APP_HOME=/home/policr_mini
ENV LANG=C.UTF-8 \
    PATH="$APP_HOME/bin:$PATH"
WORKDIR $APP_HOME
COPY --from=release /src/_build/prod/rel/policr_mini $APP_HOME
RUN set -xe \
    && apk add --no-cache --virtual .policr_mini-rundeps \
    ncurses \
    libstdc++
ENTRYPOINT [ "policr_mini", "start" ]
