#!/bin/bash
set -e -v

hack --apply --destdir /tmp/hackbin --clean hackinator.recipe
cp kb.recipe /tmp/hackbin/
