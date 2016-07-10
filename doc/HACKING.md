Hacking Node
=====================

This document covers some of the undocumented, unofficial, and unsupported
things that can be done in Node.js. These may be useful for debugging and node
development, but should not be relied on for production or stable use.

#### Enable the d8 shell

Node doesn't build the the v8 REPL (called d8) by default, however it may
occasionally be useful to run v8 commands directly from d8, in which case you
can build node with the `--enable-d8` configure option.

```
./configure --enable-d8 && make -j8
```

Note that this option isn't officially documented or supported.
