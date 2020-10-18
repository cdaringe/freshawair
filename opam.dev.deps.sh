#!/usr/bin/env sh
set -ex

. opam.deps.sh

opam pin add -y -n git+https://github.com/ocaml/ocaml-lsp
opam install \
  "merlin" \
  "ocamlformat" \
  "odoc"
