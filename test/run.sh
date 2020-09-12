#!/usr/bin/env bash
set -eu

export PATH="$(pwd)/../libexec:$PATH"

shopt -s nullglob

inputs=(*.in)
count="${#inputs[@]}"

echo "1..$count"

function get_diagnostics() {
  input=$1
  output=$2
  echo "Expected:"
  echo "========="
  cat "$output"

  echo
  echo "Actual:"
  echo "======="
  git-natp <"$input"

  echo
  echo "Diff:"
  echo "====="
  git-natp <"$input" | diff - "$output"

  echo
}

function print_diagnostics() {
  get_diagnostics "$@" | while read line
  do
    echo "# $line"
  done
}

for i in "${!inputs[@]}"
do
  test_number=$((i + 1))
  input="${inputs[i]}"
  testcase="${input%.in}"
  output="$testcase.out"
  if git-natp <"$input" | cmp -s - "$output"
  then
    echo "ok $test_number - $testcase"
  else
    echo "not ok $test_number - $testcase"
    print_diagnostics $input $output
  fi
done
