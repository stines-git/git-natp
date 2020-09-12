#!/usr/bin/env bash
set -eu

TEST_DIR=$(dirname ${BASH_SOURCE[0]})
TEST_DIR=$(cd "$TEST_DIR" >/dev/null 2>&1 && pwd)
TMP_DIR="$TEST_DIR/tmp"

export PATH="$TEST_DIR/../libexec:$PATH"

shopt -s nullglob

inputs=($TEST_DIR/*.in)
count="${#inputs[@]}"

echo "1..$((count * 2))"

function get_diagnostics() {
  actual="$1"
  output="$2"
  echo "Expected:"
  echo "========="
  cat "$output"

  echo
  echo "Actual:"
  echo "======="
  printf "$actual"

  echo
  echo "Diff:"
  echo "====="
  printf "$actual" | diff - "$output"

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
  filename=$(basename "$input")
  testcase="${filename%.in}"
  output="${input%.in}.out"

  if [[ ( $# -gt 0 ) && ( $test_number -ne $1 ) ]]
  then
    echo "ok $test_number - $testcase # SKIPPED"
    continue
  fi

  # Capture output. Note: insert EOF marker to presever trailing new-line.
  actual=$(git-natp <"$input"; echo EOF)
  actual="${actual%EOF}"

  if printf "$actual" | cmp -s - "$output"
  then
    echo "ok $test_number - $testcase"
  else
    echo "not ok $test_number - $testcase"
    print_diagnostics "$actual" $output
  fi
done

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

for i in "${!inputs[@]}"
do
  test_number=$((count + i + 1))
  input="${inputs[i]}"
  filename=$(basename "$input")
  testcase="${filename%.in}"

  if [[ ( $# -gt 0 ) && ( $test_number -ne $1 ) ]]
  then
    echo "ok $test_number - $testcase # SKIPPED"
    continue
  fi

  testcase_dir="$TMP_DIR/$testcase"
  mkdir "$testcase_dir"
  cd "$testcase_dir"
  git init >/dev/null
  git-natp create <"$input"

  if git-natp compare <"$input" >/dev/null
  then
    echo "ok $test_number - $testcase"
  else
    echo "not ok $test_number - $testcase"
  fi
done
