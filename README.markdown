git-natp: Not A Tree Parser
===========================

If you draw an ASCII diagram of a git commit graph,

```
A1---A2---A3---BB12--BB23--BB34--BB4 master
      \      .~'/  .~'/  .~'/  .~'
       \  .~'  /.~'  /.~'  /.~'
        B1----B2----B3----B4 feature
```

then this tool can do two things:

1. `git natp create ` will generate a new git respository that follows your commit graph structure.
2. `git natp compare` will test to see if the current git repository follows your diagram.

Both commands accept the commit graph from `stdin`.

## Install

To install this globally, run `sudo make install` and the scripts will be copied to
`/usr/local/bin/...`. Similarly, `sudo make uninstall` removes them.


## Testing

To run the tests, just execute the `run.sh` script in the `test` folder or run `make test`.

```sh
./test/run.sh
```

The output should be in TAP format.

