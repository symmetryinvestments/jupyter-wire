Example jupyter kernel
----------------------

To install, copy `kernel.json` from this directory to
`~/.local/share/jupyter/kernels/<name>/kernel.json`. The directory
name can be anything. The `example_kernel` executable build by `dub`
will have to be in the `PATH`, otherwise edit `kernel.json` to point
to the path where it is located.

And that's it. When you run `jupyter notebook` you'll see `jupyter-wire-example`
as one of the available kernels. The example here supports the following (case-sensitive)
commands:

* 99
* hello
* inc
* dec
* print
