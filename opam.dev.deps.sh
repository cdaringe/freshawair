#!/usr/bin/env sh
set -ex

. opam.deps.sh

opam install \
  "merlin" \
  "ocamlformat" \
  "odoc"
