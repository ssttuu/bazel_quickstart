"""Custom repository-specific wrappers for Bazel rules_rust"""

load(
    "@rules_rust//rust:defs.bzl",
    _rust_binary = "rust_binary",
    _rust_library = "rust_library",
    _rust_proc_macro = "rust_proc_macro",
    _rust_test = "rust_test",
)

def monorepo_crate_name(name):
    """Generate a crate name for the monorepo.

    The bazel package name is used as the base, and the provided name is appended.
    If the bazel package name already ends with the provided name, it is not appended.
    All invalid characters are replaced with underscores.

    Examples:
    1. If the bazel package name is "a/b" and the provided name is "c",
       the resulting crate name will be "a_b_c".
    2. If the bazel package name is "a/b" and the provided name is "b",
       the resulting crate name will be "a_b".
    3. If the bazel package name is "a/b/c" and the provided name is "b_c",
       the resulting crate name will be "a_b_c".

    The reason for generating a crate name in this way is to make it easier to identify a crate's origin within the monorepo.

    Args:
        name: The name of the crate.
    Returns:
        A valid crate name for the monorepo.
    """
    if native.repository_name() not in ["@", "@{}".format(native.module_name())]:
        fail("monorepo_crate_name() is only supported in the root workspace")

    remove_invalid_chars = lambda s: s.replace("/", "_").replace("-", "_")

    crate_name = remove_invalid_chars(native.package_name())
    if not crate_name.endswith(name):
        crate_name += "_" + name

    return remove_invalid_chars(crate_name)

def get_rustc_flags(rustc_flags):
    return select({
        "@bazel_quickstart//tools/settings:lint.enabled": [
            "-Dclippy::as_underscore",
            "-Dclippy::assigning_clones",
            "-Dclippy::bool_to_int_with_if",
            "-Dclippy::cloned_instead_of_copied",
            "-Dclippy::clone_on_ref_ptr",
            "-Dclippy::copy_iterator",
            "-Dclippy::dbg_macro",
            "-Dclippy::debug_assert_with_mut_call",
            "-Dclippy::default_trait_access",
            "-Dclippy::default_union_representation",
            "-Dclippy::doc_link_with_quotes",
            "-Dclippy::fallible_impl_from",
            "-Dclippy::format_push_string",
            "-Dclippy::get_unwrap",
            "-Dclippy::implicit_clone",
            "-Dclippy::inefficient_to_string",
            "-Dclippy::lossy_float_literal",
            "-Dclippy::print_stderr",
            "-Dclippy::print_stdout",
            "-Dclippy::single_char_lifetime_names",
            "-Dinvalid_html_tags",
            "-Dmissing_docs",
            "-Dmissing_crate_level_docs",
            "-Dunused_crate_dependencies",
        ],
        "//conditions:default": [],
    }) + (rustc_flags if type(rustc_flags) == "select" else select({
        "//conditions:default": rustc_flags,
    })) + select({
        "//conditions:default": [
        ],
    })

def rust_binary(name, srcs = [], rustc_flags = [], **kwargs):
    """Rust binary rule with monorepo crate name generation and test support.

    Args:
        name: The name of the binary.
        srcs: The source files for the binary.
        rustc_flags: Additional flags to pass to rustc.
        **kwargs: Additional keyword arguments to pass to the rust_binary rule.
    """
    if not srcs:
        srcs = ["{}.rs".format(name)]

    kwargs, test_kwargs = _split_test_kwargs(kwargs)

    _rust_binary(
        name = name,
        crate_name = monorepo_crate_name(name),
        srcs = srcs,
        rustc_flags = get_rustc_flags(rustc_flags),
        **kwargs
    )

    rust_test(
        name = name + ".test",
        crate = name,
        **test_kwargs
    )

def rust_library(name, srcs = [], rustc_flags = [], **kwargs):
    """Rust library rule with monorepo crate name generation and test support.

    Args:
        name: The name of the library.
        srcs: The source files for the library.
        rustc_flags: Additional flags to pass to rustc.
        **kwargs: Additional keyword arguments to pass to the rust_library rule.
    """
    if not srcs:
        srcs = native.glob(["**/*.rs"])

    kwargs, test_kwargs = _split_test_kwargs(kwargs)

    _rust_library(
        name = name,
        crate_name = monorepo_crate_name(name),
        srcs = srcs,
        rustc_flags = get_rustc_flags(rustc_flags),
        **kwargs
    )

    rust_test(
        name = name + ".test",
        crate = name,
        **test_kwargs
    )

def rust_proc_macro(name, srcs = [], rustc_flags = [], **kwargs):
    """Rust procedural macro rule with monorepo crate name generation and test support.

    Args:
        name: The name of the procedural macro.
        srcs: The source files for the procedural macro.
        rustc_flags: Additional flags to pass to rustc.
        **kwargs: Additional keyword arguments to pass to the rust_proc_macro rule.
    """
    if not srcs:
        srcs = native.glob(["**/*.rs"])

    kwargs, test_kwargs = _split_test_kwargs(kwargs)

    _rust_proc_macro(
        name = name,
        crate_name = monorepo_crate_name(name),
        srcs = srcs,
        rustc_flags = get_rustc_flags(rustc_flags),
        **kwargs
    )

    rust_test(
        name = name + ".test",
        crate = name,
        **test_kwargs
    )

def rust_test(name, crate, srcs = None, rustc_flags = [], **kwargs):
    _rust_test(
        name = name,
        crate = crate,
        crate_name = monorepo_crate_name(name),
        srcs = srcs,
        rustc_flags = get_rustc_flags(rustc_flags),
        testonly = True,
        **kwargs
    )

def _split_test_kwargs(kwargs):
    """Split test-related kwargs from the rest of the kwargs.

    Args:
        kwargs: The keyword arguments to split.
    Returns:
        A tuple containing two dictionaries: the non-test-related kwargs and the
        test-related kwargs.
    """
    out_kwargs = {}
    out_test_kwargs = {}
    for key, value in kwargs.items():
        if key.startswith("test_"):
            out_test_kwargs[key[5:]] = value
        else:
            out_kwargs[key] = value

    return out_kwargs, out_test_kwargs
