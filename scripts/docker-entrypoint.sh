#!/bin/bash
set -e
run_paper() {
  # Start server
  bash start.sh
}

case "$1" in
    serve)
        shift 1
        run_paper
        ;;
    *)
        exec "$@"
esac

