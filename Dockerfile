# FROM --platform=$BUILDPLATFORM rust as base
FROM rust:1.84.0 as base
RUN apt-get install libssl-dev openssl
WORKDIR /app

FROM base as chef
RUN cargo install cargo-chef

# FROM --platform=$BUILDPLATFORM chef AS planner
FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS build
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY . .
RUN cargo build -p agent --release

FROM base as release
COPY --from=build /app/target/release/agent ./
ENTRYPOINT [ "./agent" ]
