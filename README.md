# Origami 0.6 (pre-release)

> This a pre-release before [XML Amsterdam](http://www.xmlamsterdam.com/) where I will be presenting Origami. Soon after I will release 0.6.

For now see the [wiki][wiki] for (somewhat) up to date documentation.

## Requirements

- BaseX 8.3

Other XML databases after 1.0.

## Getting started

- Some tutorials can be found on my [blog][blog].
- The [demo code](https://github.com/xokomola/origami-app)
- For documentation see the [wiki][wiki].
- The [test][tests] subdirectory contains the unit tests.

Run the unit tests:

    basex -t test

### Import

```
xquery version "3.1";

import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami/origami.xqm'; 
```

[examples]: https://github.com/xokomola/origami/tree/master/examples
[tests]: https://github.com/xokomola/origami/tree/master/test
[blog]: http://xokomola.com/
[wiki]: https://github.com/xokomola/origami/wiki

