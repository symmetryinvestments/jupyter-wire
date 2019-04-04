jupyter-wire
------------

[![Build Status](https://travis-ci.org/kaleidicassociates/jupyter-wire.png?branch=master)](https://travis-ci.org/kaleidicassociates/jupyter-wire)


An implementation of the [Jupyter wire
protocol](https://jupyter-client.readthedocs.io/en/stable/messaging.html#wire-protocol)
in [D](https://dlang.org).

This library was written so that any backend written in or callable by D can be
a jupyter kernel. A backend must be a D type that satisfies the following
compile-time interface:

```d
import jupyter.wire.kernel: LanguageInfo, ExecutionResult;
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

import jupyter.wire.kernel: Main;
mixin Main!MyBackend;
```

Otherwise, initialise as necessary and call `Kernel.run`:

```d
import jupyter.wire.kernel: kernel;
auto k = kernel(backend, connectionFileName);
k.run;
```

Please consult the `example` directory for a working (albeit silly) kernel.


## Windows

Set the environment variables `ZMQ_DIR_32` and/or `ZMQ_DIR_64` for where to find the `zmq.lib`
when building. Remember to copy the revelant .dll to the executable path.
