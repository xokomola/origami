# Origami 0.4

Origami is a templating library for XQuery (3.1) inspired by XSLT and the
[Enlive](https://github.com/cgrand/enlive) templating library for Clojure.
Currently it supports the [BaseX](http://basex.org) database version 8.0.

IMPORTANT: This library is not yet ready for production use and will change
during the next few releases. I feel no obligation to maintain backwards
compatibility but I will try to keep this README and the [blog
posts](http://xokomola.com/) up-to-date with the latest release.

## Features

- Transform nodes using XSLT-style transformations.

- Extract nodes using composable selectors which are XPath expressions or XQuery
  functions.

- Build composable templates for rendering HTML views or XML.

## Limitations

- No namespace support (planned for 0.5)

## Requirements

- BaseX 8.0 or higher (at least 2014121 snapshot)

## Getting started

- Some tutorials can be found on my [blog][blog].

- For documentation see the [wiki][wiki].

- The [examples][examples] subdirectory contains examples.

- The [test][tests] subdirectory contains the unit tests.

Run an example:

~~~xquery
> basex examples/uppercase.xq
~~~

Run the unit tests:

~~~xquery
> basex -t test
~~~

Run the example (integration) tests:

~~~xquery
> basex -t examples
~~~

### Import

To use Origami transformers import the module.

~~~xquery
import module namespace xf = 'http://xokomola.com/xquery/origami'
  at 'core.xqm';
~~~

[examples]: https://github.com/xokomola/origami/tree/master/examples
[tests]: https://github.com/xokomola/origami/tree/master/test
[blog]: http://xokomola.com/
[wiki]: https://github.com/xokomola/origami/wiki

