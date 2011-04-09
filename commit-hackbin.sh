#!/bin/bash
set -e -v

revision=`git log -n 1 --format=format:%H`
echo revision $revision
cd /code/hackbin
cp /tmp/hackbin/* .
git commit -a -m "built from https://github.com/awwx/hack commit $revision"
