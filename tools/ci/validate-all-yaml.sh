#!/bin/sh

TOPLEVEL=$(git rev-parse --show-toplevel)
cd $TOPLEVEL

git ls-files |
	grep -v 'vagrant' |
	grep '\.yaml' |
	xargs python ${TOPLEVEL}/tools/ci/validate-yaml.py -v || exit 1

