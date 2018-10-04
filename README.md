jupyter-wire
------------

An implementation of the [Jupyter wire
protocol](https://jupyter-client.readthedocs.io/en/stable/messaging.html#wire-protocol)
in [D](https://dlang.org).

This library was written so that any backend written in or callable by D can be
a jupyter kernel. A backend must be a D type that satisfies the following
compile-time interface:

```d
LanguageInfo info = T.init.languageInfo;
ExecutionResult result = T.init.execute("foo");
```

For a backend type that doesn't require initialisation, the following code is sufficient:

```d
struct MyBackend {
    enum languageInfo = LanguageInfo(/*...*/);
    ExecutionResult execute(in string code) {
       // ...
    }
}

mixin Main!MyBackend;
```

Otherwise, initialise as necessary and call `Kernel.run`:

```d
import jupyter.wire.kernel: Kernel;
auto k = kernel(backend, connectionFileName);
k.run;
```

Please consult the `example` directory for a working (albeit silly) kernel.
