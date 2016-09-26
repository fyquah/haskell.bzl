# haskell.bzl

Adding haskell skylark rules to [bazel](https://www.bazel.io/). I have no plans to actively work
on this project - rather, I am simply adding features when I need to use them.

## Goals

[x] Support haskell_library and haskell_binary
[] Support data dependency in both of the above rules
[] haskell_test
[] Adding tests (or a simply wireframe for tests)
[] Support depending on cc_libraries
[] Make the setup process easier (Right now, you need to add a symlink to your ghc in <project-root>/ghc)


## License

MIT
