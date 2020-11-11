#!/usr/bin/env sh
set -ex

# remove pin pending merge of https://github.com/bobbypriambodo/ezpostgresql/pull/6
opam pin add -y -n git+https://github.com/cdaringe/ezpostgresql#c8b6af1
opam install \
  "ezpostgresql" \
  "opium" \
  "core" \
  "dune" \
  "lwt_ppx" \
  "ppx_deriving_yojson" \
  "tls>=0.12.0" \
  "uri" \
  "yojson"
