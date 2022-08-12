# PkgApp.jl

Specifying applications in Julia.

This package is a prototype to explore possible ways to define "Application" projects in Julia, see [Pkg.jl issue #1962](https://github.com/JuliaLang/Pkg.jl/issues/1962).

The basic idea is that a Julia project can define an "apps" section in its Project.toml, which will speciy the various application entrypoints.

The simplest possible application is a directory containting script which is designed to be called from the command line (e.g. `hello_world.jl`), along with a `Project.toml` file specifying this as the entrypoint:
```toml
[apps.hello_script]
type = "script"
script = "hello_world.jl"
```

Building this application will create an executable file wrapper `bin/hello_script` which will call this script with the appropriate environment set.

A more complicated application would consist of a regular Julia package containing a "main" function which takes an `ARGS` argument and returns a `Cint`. The entrypoint would then be specified as
```toml
name = "MyApp"

[apps.hello_function]
type = "function"
function = "MyApp.hello_world"
```
