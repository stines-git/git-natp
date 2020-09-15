#!/usr/bin/env bash
set -eu

TEST_DIR=$(dirname ${BASH_SOURCE[0]})
TEST_DIR=$(cd "$TEST_DIR" >/dev/null 2>&1 && pwd)
TMP_DIR="$TEST_DIR/tmp"

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

export PATH="$TEST_DIR/..:$PATH"

shopt -s nullglob

inputs=($TEST_DIR/*.in)
count="${#inputs[@]}"

echo "1..$((count * 5 + 1))"

function print_diff() {
  expected="$1"
  actual="$2"
  echo "Expected:"
  echo "========="
  echo "$expected"
  echo "========="

  echo
  echo "Actual:"
  echo "======="
  echo "$actual"
  echo "======="

  echo
  echo "Diff:"
  echo "====="
  diff <(echo "$expected") <(echo "$actual")
  echo "====="

  echo
}

function print_diagnostics() {
  while read line
  do
    echo "# $line"
  done
}

# Pipe all stderr to a background process that prepends them with hashes.
mkfifo "$TMP_DIR/diagnostics"
print_diagnostics <"$TMP_DIR/diagnostics" &
exec 2> "$TMP_DIR/diagnostics"

for i in "${!inputs[@]}"
do
  test_number=$((i + 1))
  input="${inputs[i]}"
  filename=$(basename "$input")
  testcase="${filename%.in} parse"
  output="${input%.in}.out"

  if [[ ( $# -gt 0 ) && ( $test_number -ne $1 ) ]]
  then
    echo "ok $test_number - $testcase # SKIPPED"
    continue
  fi

  actual=$(git-natp <"$input")

  if cmp -s <(echo "$(<$output)") <(echo "$actual")
  then
    echo "ok $test_number - $testcase"
  else
    echo "not ok $test_number - $testcase"
    print_diff "$(<$output)" "$actual" >&2
  fi
done

for i in "${!inputs[@]}"
do
  test_number=$((count + i + 1))
  input="${inputs[i]}"
  filename=$(basename "$input")
  testcase="${filename%.in} - create - each commit adds single file"

  if [[ ( $# -gt 0 ) && ( $test_number -ne $1 ) ]]
  then
    echo "ok $test_number - $testcase # SKIPPED"
    continue
  fi

  testcase_dir="$TMP_DIR/$testcase"
  mkdir "$testcase_dir"
  cd "$testcase_dir"
  git-natp create <"$input"

  for branch in $(git for-each-ref --format="%(refname)" refs/heads/)
  do
    for commit in $(git rev-list $branch)
    do
      subject=$(git show --no-patch --format=%s "$commit")
      mapfile -t changed_files < <(git diff-tree --no-commit-id --name-status -r -m -c --root $branch)
      num_changed="${#changed_files[@]}"
      if [[ "$num_changed" -ne 1 ]]
      then
        echo "not ok $test_number - $testcase"
        echo "Commit $subject $commit from branch $branch changed $num_changed files" >&2
        for change in "${changed_files[@]}"
        do
          echo "$change" >&2
        done
        exit 1
      fi
      changed_file=(${changed_files[0]})
      if [[ ! ( "${changed_file[0]}" =~ ^A+$ ) ]]
      then
        echo "not ok $test_number - $testcase"
        echo "Commit $subject $commit from branch $branch did not add file: ${changed_file[@]}" >&2
        echo "The change was: ${changed_file[@]}" >&2
        exit 1
      fi
    done
  done
  echo "ok $test_number - $testcase"
done

for i in "${!inputs[@]}"
do
  test_number=$((count * 2 + i + 1))
  input="${inputs[i]}"
  filename=$(basename "$input")
  testcase="${filename%.in} - create and compare"

  if [[ ( $# -gt 0 ) && ( $test_number -ne $1 ) ]]
  then
    echo "ok $test_number - $testcase # SKIPPED"
    continue
  fi

  testcase_dir="$TMP_DIR/$testcase"
  mkdir "$testcase_dir"
  cd "$testcase_dir"
  git-natp create <"$input"

  if git-natp compare <"$input" >/dev/null
  then
    echo "ok $test_number - $testcase"
  else
    echo "not ok $test_number - $testcase"
    exit 1
  fi
done

for i in "${!inputs[@]}"
do
  test_number=$((count * 3 + i + 1))
  input1="${inputs[i]}"
  input2="${inputs[$(((i + 1) % count))]}"
  filename1=$(basename "$input1")
  filename2=$(basename "$input2")
  testcase="${filename1%.in} - ${filename2%.in} - compare same subjects different structure"

  if [[ ( $# -gt 0 ) && ( $test_number -ne $1 ) ]]
  then
    echo "ok $test_number - $testcase # SKIPPED"
    continue
  fi

  testcase_dir="$TMP_DIR/$testcase"
  mkdir "$testcase_dir"
  cd "$testcase_dir"
  sed "s/[a-zA-Z0-9]/A/g" <"$input1" | git-natp create

  if sed "s/[a-zA-Z0-9]/A/g" <"$input2" | git-natp compare >/dev/null
  then
    echo "not ok $test_number - $testcase"
    exit 1
  else
    echo "ok $test_number - $testcase"
  fi
done

for i in "${!inputs[@]}"
do
  test_number=$((count * 4 + i + 1))
  input="${inputs[i]}"
  filename=$(basename "$input")
  testcase="${filename%.in} - compare same structure different subjects"

  if [[ ( $# -gt 0 ) && ( $test_number -ne $1 ) ]]
  then
    echo "ok $test_number - $testcase # SKIPPED"
    continue
  fi

  if sed "s/[a-zA-Z0-9]/A/g" <"$input" | cmp -s - "$input"
  then
    echo "ok $test_number - $testcase # SKIPPED because nothing to rename"
    continue
  fi

  testcase_dir="$TMP_DIR/$testcase"
  mkdir "$testcase_dir"
  cd "$testcase_dir"
  git-natp create <"$input"

  if sed "s/[a-zA-Z0-9]/A/g" <"$input" | git-natp compare >/dev/null
  then
    echo "not ok $test_number - $testcase"
    exit 1
  else
    echo "ok $test_number - $testcase"
  fi
done

test_number=$((count * 5 + 1))
testcase="Custom commit commands"
if [[ ( $# -gt 0 ) && ( $test_number -ne $1 ) ]]
then
  echo "ok $test_number - $testcase # SKIPPED"
else
  testcase_dir="$TMP_DIR/$testcase"
  mkdir "$testcase_dir"
  cd "$testcase_dir"
  # File 'a' is created to test globbing bugs from unquoted variables like [master]
  git-natp create \
    --cmd A "touch newfile" \
    --cmd D "rm newfile;touch other another" \
    --cmd F "touch a; echo change >> another" \
<<-"EOF"
    A---B---C----F master
         `D----E'
EOF

  function assert_file_changes() {
    rev=$1
    subject=$2
    expected=$3
    actual=$(git diff-tree --no-commit-id --name-status -r -m -c --root "$rev")
    if [[ "$expected" != "$actual" ]]
    then
      echo "not ok $test_number - $testcase"
      echo "Commit $subject have unexpected or missing changes" >&2
      print_diff "$expected" "$actual" >&2
      exit 1
    fi
  }

  rev_A="master~3"
  rev_D="master^2~"
  rev_F="master"

  compare_failed=0
  git-natp compare <<-"EOF" >/dev/null || compare_failed=1
    A---B---C----F master
         `D----E'
EOF
  if ((compare_failed))
  then
    echo "not ok $test_number - $testcase"
    echo "Comparison failed" >&2
    exit 1
  fi

  assert_file_changes "$rev_A" "A" $'A\tcommits/A\nA\tnewfile' || exit 1
  assert_file_changes "$rev_D" "D" $'A\tanother\nA\tcommits/D\nD\tnewfile\nA\tother' || exit 1
  assert_file_changes "$rev_F" "F" $'AA\ta\nAM\tanother\nAA\tcommits/F' || exit 1
  echo "ok $test_number - $testcase"
fi
