#!/bin/bash
set -e -v

/code/hackbin/hack --apply --destdir /tmp/hackbin --clean hackinator.recipe
cp kb.recipe /tmp/hackbin/
