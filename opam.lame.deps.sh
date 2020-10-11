#!/usr/bin/env bash
set -ex

opam pin add -y git+https://github.com/ManasJayanth/ezpostgresql#5664b90
opam pin add -y git+https://github.com/ocaml/ocaml-lsp
opam install -y \
  "cohttp" \
  "cohttp-lwt-unix" \
  "core" \
  "lwt_ppx" \
  "ppx_deriving_yojson" \
  "yojson" \
  "dune" \
  "merlin" \
  "ocamlformat" \
  "odoc" \
  "uri"
