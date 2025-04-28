# Bazel Quickstart

This is a template repository for starting a new project that uses Bazel as the build system.
It contains a simple Rust project that is built using Bazel.

## Building & Testing

This repository uses [Bazel](https://bazel.build/) as the build system. To build the code, run:

```bash
bazel build //...
```

To run the tests, run:

```bash
bazel test //...
```

## Linting & Formatting

Most of the linters can be run with the `--config=lint` flag. For example:

```bash
bazel test --config=lint //...
```

The Bazel file formatter, `buildifier`, does not run as an aspect, so it needs to be run
separately.

```bash
bazel run buildfmt.check
```

To run all of the formatters:

```bash
bazel run fmt
```

## Updating dependencies

### Updating Rust crates

Modify the `Cargo.toml` file to update the dependencies.

Note that there is no need to overly specify versions of dependencies as Bazel
will use the versions specified in the `Cargo.lock` file. It is recommended to use versions such as "0" or "0.1" for dependency specifications
so that Cargo can find the latest minimal set of dependencies that satisfy the requirements.

Add `@crates_io//:crate_name` to the `deps` attribute of the `rust_library` or `rust_binary` rule in the `BUILD.bazel` file.

### Repinning dependencies

To update the dependencies, run:

```bash
bazel mod deps --lockfile_mode=refresh
```

Re-generate the `rust_project.json` file by running:

```bash
bazel run gen_rust_project
```

## Project Structure

The project structure is intended to support a monorepo with multiple projects and multiple languages.

Each project should have its own directory in the root of the repository. The exception is the `tools` directory, which
contains bazel rules and other build functionality.

Shared code should be placed in a common directory which is specific to the company or organization. For instance, if
your company is named "Cloud Kitchen", you might have a directory named `ck/` that contains shared code. As a last
resort name it `common/` or `shared/` but not that this will be in all of your import paths. This template uses `ss/`
as the shared code directory.

### Rust Code

Rust code is structured as one crate per directory except for the `cmd/` directories which contain binaries. The binary
name is expected to be the same as rust file name.

```bazel
# my_project/cmd/BUILD.bazel
load("//tools/rust:defs.bzl", "rust_binary")

rust_binary(
    # This corresponds to the file name `my_binary.rs`.
    name = "my_binary",
    # You can optionally override the `srcs` attribute to customize the sources but it is discouraged.
    deps = [
        "//my_project/lib",
    ],
)
```
