#!/bin/bash
# Copyright 2015 The Go Authors. All rights reserved.
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file.

set -e

# We need to test enough GOOS/GOARCH combinations to pick up all the
# package dependencies.
gooslist="windows linux darwin solaris"
goarchlist="386 amd64 arm arm64 ppc64"

echo NOTE: errors about loading internal/syscall/windows are ok

deps_of() {
	for goos in $gooslist
	do
		for goarch in $goarchlist
		do
			GOOS=$goos GOARCH=$goarch go list -tags cmd_go_bootstrap -f '{{range .Deps}}{{$.ImportPath}} {{.}}
{{end}}' $*
		done
	done | sort -u | grep . | grep -v ' unsafe$'
}

all="$(deps_of cmd/go | awk '{print $2}') cmd/go"
deps_of $all >tmp.all.deps

(
	echo '// generated by mkdeps.bash'
	echo
	echo 'package main'
	echo
	echo 'var builddeps = map[string][]string{'
	for pkg in $all
	do
		echo -n "\"$pkg\": {"
		for dep in $(awk -v pkg=$pkg '$1==pkg {print $2}' tmp.all.deps)
		do
			echo -n "\"$dep\","
		done
		echo '},'
	done
	echo '}'
) |gofmt >deps.go

rm -f tmp.all.deps
