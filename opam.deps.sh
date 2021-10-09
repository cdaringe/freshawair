#!/usr/bin/env sh
set -ex

# remove pin pending merge of https://github.com/bobbypriambodo/ezpostgresql/pull/6
opam pin add -yn git+https://github.com/cdaringe/ezpostgresql#c8b6af1
# opam pin add -yn git+https://github.com/ocaml-multicore/eio#5245ca5
#   "eio" \

opam install -y \
  "ezpostgresql" \
  "opium" \
  "cmdliner" \
  "dune" \
  "lwt_ppx" \
  "ppx_deriving_yojson" \
  "cohttp" \
  "cohttp-lwt-unix" \
  "tls>=0.12.0" \
  "odate" \
  "uri" \
  "yojson" \
  "ppx_jane"
