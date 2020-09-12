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
2. `git natp compare` will test to see if the current git repository follows your diagram.

Both commands accept the commit graph from `stdin`.

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

## Install

To install this globally, run `sudo make install` and the scripts will be copied to
`/usr/local/bin/...`. Similarly, `sudo make uninstall` removes them.


## Testing

To run the tests, just execute the `run.sh` script in the `test` folder or run `make test`.

```sh
./test/run.sh
```

The output should be in TAP format.

