# docker buildx build --progress plain --platform linux/arm/v7 -t deleteme .
# ... linux/amd64,linux/arm64,
# https://github.com/esy/esy/blob/master/Dockerfile
FROM cdaringe/freshawair:esy-cache AS builder
COPY . .
RUN esy install && esy build --release
