# Origami 0.6

Origami is a templating library for XQuery (3.1). It consists of two different modules which support different templating paradigms.

- Origami-ω is inspired by the Clojure [Enlive](https://github.com/cgrand/enlive) templating library. It makes use of Origami-μ but it can be used without μ's templating structures.

- Origami-μ is a micro-template module that defines XML or JSON structures using XQuery 3.1 arrays and maps. It is inspired by the Clojure [Hiccup](https://github.com/weavejester/hiccup) templating library. This module can be used independently of the other.

Currently it can be used with the [BaseX](http://basex.org) database version 8.2.

IMPORTANT: This library is not yet ready for production use and will change
during the next few releases. I feel no obligation to maintain backwards
compatibility but I will try to keep this README and the [blog
posts](http://xokomola.com/) up-to-date with the latest release.

## Features

- Transform nodes using XSLT-style transformations.

- Extract nodes using composable selectors which are XPath expressions or XQuery functions.

- Build composable templates for rendering HTML views or XML.

## Limitations

- No namespace support (planned for 0.5)

## Requirements

- BaseX 8.0

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

To use Origami-ω transformers import the `om.xqm` module.

~~~xquery
import module namespace xf = 'http://xokomola.com/xquery/origami'
  at 'origami/om.xqm';
~~~

To use Origami-μ transformers import the `mu.xqm` module.

~~~xquery
import module namespace xf = 'http://xokomola.com/xquery/origami'
  at 'origami/mu.xqm';
~~~

Of course, you can use any other namespace prefix if you feel the
greek characters are too awkward or cumbersome to type. In that case I suggest you use `om` and `mu` respectively.

[examples]: https://github.com/xokomola/origami/tree/master/examples
[tests]: https://github.com/xokomola/origami/tree/master/test
[blog]: http://xokomola.com/
[wiki]: https://github.com/xokomola/origami/wiki

