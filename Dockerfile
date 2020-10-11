FROM ocaml/opam2:debian-stable AS builder
SHELL ["/bin/bash", "-c"]
WORKDIR /app
USER root
RUN apt-get install -y \
  # for esy
  curl \
  git \
  # opam lib build-time dependencies required by packages in package.json::dependencies
  m4 \
  musl-dev \
  libc-dev \
  # postgresql-client \
  # postgresql-dev \
  libpq-dev \
  # hacks
  tree
# install node
# ENV NODE_VERSION 14.13.1
# ENV NVM_DIR="$HOME/.nvm"
# ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
# RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.36.0/install.sh | bash \
#   && source $NVM_DIR/nvm.sh \
#   && nvm install ${NODE_VERSION}

# # install esy
# RUN npm install --verbose --global esy

# # use esy
# RUN ls -al $NVM_DIR/versions/node/v$NODE_VERSION/bin
# COPY package.json .
# RUN ls -al $NVM_DIR/versions/node/v$NODE_VERSION/bin/esy \
#         && $NVM_DIR/versions/node/v$NODE_VERSION/bin/esy
# RUN esy
# COPY . .
# RUN esy build --release
# RUN opam switch create ocaml-base-compiler.4.10
RUN opam update
# good luck getting `opam import` to work, or an esy compilation working with
# arm. just gooooooood luck. so don't. do lame stuff instead.
COPY opam.lame.deps.sh .
RUN eval $(opam env) && opam switch && bash opam.lame.deps.sh
COPY . .
RUN opam exec -- dune build --release bin/Fresh.exe
