Install a copy of <https://github.com/mit-plv/bbv> (e.g., by installing the
`coq-bbv` coq opam package).  If it's built but not installed, set the
`BBV_DIR` environment variable to the directory containing the built files.
Then run `./build`.

The models were built with
* `sail` commit `f0f778ef`
* `sail-riscv` commit `0b8bf69`
and checked against bbv version 1.1 and coq 8.9.1.
