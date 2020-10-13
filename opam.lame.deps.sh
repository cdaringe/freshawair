#!/usr/bin/env bash
set -ex

opam pin add -y git+https://github.com/ManasJayanth/ezpostgresql#5664b90
opam pin add -y git+https://github.com/ocaml/ocaml-lsp
opam install -y \
  "ansiterminal" \
  "cohttp-lwt-unix" \
  "cohttp" \
  "core" \
  "dune" \
  "lwt_ppx" \
  "merlin" \
  "ocamlformat" \
  "odoc" \
  "ppx_deriving_yojson" \
  "tls" \
  "uri" \
  "yojson"
