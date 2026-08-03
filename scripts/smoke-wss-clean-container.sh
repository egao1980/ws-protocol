#!/usr/bin/env bash
# Clean ubuntu:24.04 linux/amd64: OCI cl-stack-ssl + local WSS echo smoke.
# Requires: docker, oras. No libssl-dev in the container.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${CL_STACK_SSL_VERSION:-3.4.1}"
IMAGE="ghcr.io/egao1980/cl-systems/cl-stack-ssl:${VERSION}"
CACHE="${CACHE:-/tmp/ws-protocol-wss-smoke-cache}"
PKG="$CACHE/pkg/cl-stack-ssl-${VERSION}"
QL="$CACHE/quicklisp"

mkdir -p "$CACHE/pull" "$CACHE/pkg"
if [[ ! -f "$PKG/native/libssl.so" ]]; then
  command -v oras >/dev/null || { echo "need oras" >&2; exit 1; }
  rm -rf "$CACHE/pull"/* "$CACHE/pkg"/*
  oras pull --platform linux/amd64 "$IMAGE" -o "$CACHE/pull/"
  for f in "$CACHE/pull"/*.tar.gz; do tar -xzf "$f" -C "$CACHE/pkg/"; done
fi

SMOKE_LISP="$CACHE/smoke.lisp"
cat >"$SMOKE_LISP" <<'EOF'
(require :asdf) (require :uiop)
(defvar *ssl* (uiop:getenv "CL_STACK_SSL_ROOT"))
(defvar *ws* (uiop:getenv "WS_PROTOCOL_ROOT"))
(asdf:initialize-source-registry
 `(:source-registry
   (:directory ,(uiop:ensure-directory-pathname *ssl*))
   (:tree ,(uiop:ensure-directory-pathname *ws*))
   :inherit-configuration))
(ql:quickload '("cffi" "cl-stack-ssl" "rove" "blackbird" "cl-base64"
                "bordeaux-threads" "websocket-driver" "event-emitter"
                "clack" "clack-handler-hunchentoot" "hunchentoot"
                "ws-protocol" "ws-backend-websocket-driver")
              :silent t)
(cl-stack-ssl:ensure-ssl)
(setf (uiop:getenv "WS_PROTOCOL_WSS") "1")
(setf (uiop:getenv "WS_PROTOCOL_WSS_CHILD") "1")
(asdf:test-system "ws-protocol")
(format t "~&WSS SMOKE OK~%")
#+sbcl (sb-ext:exit :code 0 :abort t)
#-sbcl (uiop:quit 0)
EOF

if [[ ! -f "$QL/setup.lisp" ]]; then
  docker run --rm --platform linux/amd64 \
    -e DEBIAN_FRONTEND=noninteractive \
    -v "$QL:/ql" \
    ubuntu:24.04 \
    bash -c 'apt-get update -qq && apt-get install -y -qq ca-certificates curl sbcl >/dev/null \
      && curl -fsSL -o /tmp/ql.lisp https://beta.quicklisp.org/quicklisp.lisp \
      && sbcl --noinform --non-interactive --load /tmp/ql.lisp \
           --eval "(quicklisp-quickstart:install :path #p\"/ql/\")" >/dev/null'
fi

docker run --rm --platform linux/amd64 \
  -e DEBIAN_FRONTEND=noninteractive \
  -e CL_STACK_SSL_ROOT=/opt/cl-stack-ssl \
  -e WS_PROTOCOL_ROOT=/opt/ws-protocol \
  -e WS_PROTOCOL_WSS=1 \
  -e LD_LIBRARY_PATH=/opt/cl-stack-ssl/native \
  -v "$PKG:/opt/cl-stack-ssl:ro" \
  -v "$QL:/ql" \
  -v "$ROOT:/opt/ws-protocol:ro" \
  -v "$SMOKE_LISP:/opt/smoke.lisp:ro" \
  ubuntu:24.04 \
  bash -c 'apt-get update -qq && apt-get install -y -qq ca-certificates sbcl >/dev/null \
    && if dpkg -l libssl-dev 2>/dev/null | grep -q ^ii; then echo FAIL:libssl-dev; exit 1; fi \
    && sbcl --noinform --non-interactive --load /ql/setup.lisp --load /opt/smoke.lisp'
