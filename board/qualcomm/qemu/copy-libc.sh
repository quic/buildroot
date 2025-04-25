#!/bin/bash

TO="${TARGET_DIR}/lib/ld-musl-hexagon.so.1"
FROM="${BINARIES_DIR}/ld-musl-hexagon.so.1"

rm -f "$TO" && mkdir -p "$(dirname "$TO")" && cp -L "$FROM" "$TO"
