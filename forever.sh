#!/bin/bash

_term() {
  echo "Caught SIGTERM signal!"
  kill -TERM 1 2>/dev/null
}

trap _term EXIT

sleep infinity
