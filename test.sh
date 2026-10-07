#!/bin/sh
set -e
test -f index.html
grep -q "<h1>" index.html
grep -q "Version:" index.html
echo "Unit tests passed"