# syntax = docker/dockerfile:1.2

FROM docker.io/library/node:18-alpine AS build-web

WORKDIR /wd

COPY web/package-lock.json web/package.json ./
RUN --mount=type=cache,target=/wd/node_modules \
    npm install
COPY web/ ./
RUN --mount=type=cache,target=/wd/node_modules \
    npm run build

FROM docker.io/library/rust:1.70-alpine AS build

ENV SYSROOT=/dummy
WORKDIR /wd

RUN apk add musl-dev
COPY Cargo.lock Cargo.toml ./
COPY src/ ./src/
COPY --from=build-web /wd/dist/ ./web/dist/
RUN --mount=type=cache,target=/wd/target \
    cargo build --bins --release \
    && mkdir -p build \
    && mv ./target/release/* ./build/

FROM scratch AS final

COPY --from=build /wd/build/encrypted-gallery /
CMD [ "/encrypted-gallery" ]