#!/usr/bin/env sh
set -ex

opam pin add -y -n git+https://github.com/ManasJayanth/ezpostgresql#5664b90
opam pin add -y -n git+https://github.com/mirage/hacl#2aae26b
opam install \
  "ezpostgresql" \
  "ansiterminal" \
  "cohttp-lwt-unix" \
  "cohttp" \
  "core" \
  "dune" \
  "lwt_ppx" \
  "ppx_deriving_yojson" \
  "tls>=0.12.0" \
  "uri" \
  "yojson"
