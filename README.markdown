git-natp: Not A Tree Parser
===========================

If you draw an ASCII diagram of a git commit graph,

```
A1---A2---A3---BB12--BB23--BB34--BB4 master
      \      .~'/  .~'/  .~'/  .~'
       \  .~'  /.~'  /.~'  /.~'
        B1----B2----B3----B4 feature
```

then this tool can do three things:

1. `git natp` will output the adjacency list of the graph.
1. `git natp create ` will generate a new git repository that follows your commit graph structure.
2. `git natp compare` will test to see if the current git repository follows your diagram. Note that commits not accessible through a branch name will be ignored.

Both commands accept the commit graph from `stdin`.

## Install

You can install this using `bpkg install ErnWong/git-natp` using [bpkg](https://github.com/bpkg/bpgk).

Alternatively, download this repo and run run `sudo make install` and the scripts will be copied to
`/usr/local/bin/...`. Similarly, `sudo make uninstall` removes them.

## Usage information

###  `git natp create`

Run this command in an empty initialised git repository.

**Caution: Don't run `git natp create` in an existing repository or it could mess up your repository.**

### `git natp compare`

Run this command in an existing git repository. If the repository commit graph matches the
diagram you supply, then it will return an exit code of 0 and output the following to `stdout`.

```
Git graph structures are equivalent
```

If the commit graphs are not the same, then it will return an exit code of 1 and output one
of the following reasons to `stdout`.

```
Branch <branch name> has a different structure.
Branch <branch name> does not exist.
Branch <branch name> exists but was not expected.
```

Since this tool checks the graph structure on a branch-by-branch basis, commits that are not
accessible from any branch (i.e. detached commits) will not be checked.

### Diagram input format

- Commit names (aka their subjects) are sequences of alphanumeric characters with no space in between.
- The diagram must be topologically sorted left to right, so that the commits to the left are the parents of the commits to the right.
- Branch names are alphanumeric character sequences that is one space to the right of a commit subject.
- Edges describe the parents of each commit, and need to be touching the commit name.
- The parent order for each commit is important. This tool orders them based on the direction of the edges that are used to connect them. Going from the child to the parent (right-to-left), a horizontal edge comes before an upwards edge, and an upwards edge comes before a downwards edge.

### Supported edges

This tool supports the following ASCII edge connectors. Each edge character has restrictions on which direction the edge can connect from and to.

The following directions are based on the perspective of the edge character. The parent side is to the left, and the child side is to the right.

| Tokens   | Parent below           | Parent horizontal      | Parent above           | Child below            | Child horizontal       | Child above            |
|----------|------------------------|------------------------|------------------------|------------------------|------------------------|------------------------|
| `+`      | Yes :heavy_check_mark: | Yes :heavy_check_mark: | Yes :heavy_check_mark: | Yes :heavy_check_mark: | Yes :heavy_check_mark: | Yes :heavy_check_mark: |
| `<`      | No  :x:                | Yes :heavy_check_mark: | No :x:                 | Yes :heavy_check_mark: | Yes :heavy_check_mark: | Yes :heavy_check_mark: |
| `>`      | Yes :heavy_check_mark: | Yes :heavy_check_mark: | Yes :heavy_check_mark: | No :x:                 | Yes :heavy_check_mark: | No :x:                 |
| `.,_`    | Yes :heavy_check_mark: | Yes :heavy_check_mark: | No :x:                 | Yes :heavy_check_mark: | Yes :heavy_check_mark: | No :x:                 |
| ``'`^*`` | No  :x:                | Yes :heavy_check_mark: | Yes :heavy_check_mark: | No :x:                 | Yes :heavy_check_mark: | Yes :heavy_check_mark: |
| `-~`     | No  :x:                | Yes :heavy_check_mark: | No :x:                 | No :x:                 | Yes :heavy_check_mark: | No :x:                 |
| `/`      | Yes :heavy_check_mark: | No  :x:                | No :x:                 | No :x:                 | No :x:                 | Yes :heavy_check_mark: |
| `\`      | No  :x:                | No  :x:                | Yes :heavy_check_mark: | Yes :heavy_check_mark: | No :x:                 | No :x:                 |

### git-natp adjacency list output format

Each line corresponds to a commit on the graph. The first token is the commit subject.
Subsequent tokens are the commit's parents in order. After every commit has been listed,
the branches will be listed in `[branch] commit` pairs.

For example, given the above diagram as `stdin`, `git natp` will output the following:

```
A1
A2 A1
B1 A2
A3 A2
B2 B1
BB12 A3 B1 B2
B3 B2
BB23 BB12 B2 B3
B4 B3
BB34 BB23 B3 B4
BB4 BB34 B4
[master] BB4
[feature] B4
```

## Testing

To run the tests, just execute the `run.sh` script in the `test` folder or run `make test`.

```sh
./test/run.sh
```

The output should be in TAP format.

To run a specific test number, supply it as a single argument:

```sh
./test/run.sh 10
```
