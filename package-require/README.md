# package-require

The idea is to search for modules in different paths based on first module component ("package").

This should make it easier to have dependencies of a various libraries installed in different places,
even outside library code. For example, if the project uses library `a` and `a` itself uses `b` (referring to it
using e.g. `(require :b.xyz)`), you can have them both installed inside `lib/` directory of your project.
Then, when library `a` requires `b`, it would search for `b` modules in `lib/b/` without having to add `lib/?.fnl`
to your `fennel.path`. `package-require` uses it's own paths, one per "package".

`package-require` does not install/manage dependencies, let alone transitive ones.
