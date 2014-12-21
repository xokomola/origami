# Origami 0.3

Origami is a templating library for XQuery (3.0) inspired by XSLT and the
[Enlive](https://github.com/cgrand/enlive) templating library for Clojure.
Currently it supports the [BaseX](http://basex.org) database version 8.0 or
higher.

For more information go the the [Wiki][wiki].

IMPORTANT: This library is not yet ready for production use and will change
during the next few releases. I feel no obligation to maintain backwards
compatibility but I will try to keep this README and the [blog
posts](http://xokomola.com/) up-to-date with the latest release.

## Features

- Transform nodes using XSLT-style transformations.

- Extract nodes using composable selectors which are XPath expressions or XQuery
  functions.

## Requirements

- BaseX 8.0 (at least [20141221 snapshot](http://basex.org/products/download/all-downloads/))

## Getting started

The `examples` subdirectory contains a few examples.

Run an example:

~~~xquery
> basex examples/uppercase.xq
~~~

The `test` subdirectory contains the unit tests.

Run the unit tests:

~~~xquery
> basex -t test
~~~

In code examples below I left out the namespace prefixes for clarity.

### Import

To use Origami transformers import the module.

~~~xquery
import module namespace xf = 'http://xokomola.com/xquery/origami'
  at 'core.xqm';
~~~

[wiki]: https://github.com/xokomola/origami/wiki

