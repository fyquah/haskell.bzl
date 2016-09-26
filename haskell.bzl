"""Bazel rules for haskell compilation."""

_GHC = "//haskell:ghc"


def _modulize_path(short_path):
  items = short_path.split("/")
  converted = []
  for item in items:
    converted.append(
        "".join([s[0].capitalize() + s[1:]
                 for s in item.split("_")]))
  return "/".join(converted)


def _get_module_name(short_path):
  """Gets the module name of a modulized short path to a .hs file."""
  name, _, _ = short_path.rpartition(".")
  return name.replace("/", ".")


def _change_extension(path, ext):
  a, b, c = path.rpartition(".")
  if c:
    return a + b + ext
  else:
    return a + "." + ext


def _capitalize_basename(path):
  a, b, c = path.rpartition("/")
  if c:
    return a + b + c[0].capitalize() + c[1:]
  else:
    return a[0].capitalize + a[1:]


def _haskell_impl(ctx, extra_flags=[]):
  """Compiles srcs/ in the rule into .o and .hi files."""
  files = []
  for src in ctx.attr.srcs:
    for f in src.files:
      files.append(f)
  deps_his = []
  deps_objs = []
  objs = []
  his = []

  for dep in ctx.attr.deps:
    if hasattr(dep, "hs"):
      deps_his.extend(list(dep.hs.his))
      deps_objs.extend(list(dep.hs.objs))

  for f in files:
    path = _modulize_path(f.short_path)
    arguments = [flag for flag in ctx.attr.flags] + extra_flags
    obj_file = ctx.new_file(_change_extension(path, "o"))
    hi_file = ctx.new_file(_change_extension(path, "hi"))
    arguments.extend([
        "-i" + obj_file.root.path,
        "-c",
        "-odir", obj_file.root.path,
        "-hidir", hi_file.root.path])
    arguments.append(f.path)
    progress_message = "ghc compiling " + path

    objs.append(obj_file)
    his.append(hi_file)
    ctx.action(
        inputs=[f] + deps_objs + deps_his,
        outputs=[obj_file, hi_file],
        executable=ctx.executable._ghc,
        arguments=arguments,
        progress_message=progress_message,
    )
  return struct(objs=set(objs + deps_objs),
                his=set(his + deps_his))


def _haskell_library_impl(ctx):
  intermediate = _haskell_impl(ctx)
  return struct(hs=intermediate)


def _haksell_binary_impl(ctx):
  extra_flags = [
      "-main-is",
      _get_module_name(_modulize_path(ctx.file.main.short_path))]
  intermediate = _haskell_impl(ctx, extra_flags=extra_flags)
  arguments = (["-o", ctx.outputs.executable.path]
                + [f.path for f in intermediate.objs]
                + extra_flags)
  ctx.action(
      inputs=[obj for obj in intermediate.objs],
      outputs=[ctx.outputs.executable],
      executable=ctx.executable._ghc,
      arguments=arguments
  )


haskell_binary = rule(
  implementation=_haksell_binary_impl,
  executable=True,
  attrs = {
      "srcs": attr.label_list(allow_files=True, mandatory=True),
      "deps": attr.label_list(),
      "data": attr.label_list(),
      "flags": attr.string_list(),
      "main": attr.label(allow_single_file=True, mandatory=True),
      "_ghc": attr.label(default=Label(_GHC),
                         executable=True,
                         allow_single_file=True)
      }
)


haskell_library = rule(
    implementation=_haskell_library_impl,
    executable=False,
    attrs = {
        "srcs": attr.label_list(allow_files=True, mandatory=True),
        "deps": attr.label_list(),
        "data": attr.label_list(),
        "flags": attr.string_list(),
        "_ghc": attr.label(default=Label(_GHC),
                           executable=True,
                           allow_single_file=True)
        }
)
