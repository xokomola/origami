# Origami 0.6

Origami is a templating library for XQuery (3.1). It consists of two different modules which support different templating paradigms.

- **Origami-ω** is inspired by the Clojure [Enlive](https://github.com/cgrand/enlive) templating library. It makes use of Origami-μ but it can be used without μ's templating structures.

- **Origami-μ** is a micro-templating module that defines XML or JSON structures using XQuery 3.1 arrays and maps. It is inspired by the Clojure [Hiccup](https://github.com/weavejester/hiccup) templating library. This module can be used independently of the other.

Currently it can be used with the [BaseX](http://basex.org) database version 8.2 and higher. Web applications using Origami will perform better with the new RESTXQCACHE option that was added in the 8.2.2 release.

STATUS: Release 0.4 and before could be characterized as a proof-of-concept. The last few months I have focused on turning Origami into a library that I could actually use in production (I already use Origami-μ in production). Because the changes are major I decided to give the next release the version number 0.6. 0.5 exists only as various experiments and in my head. The next
few releases until 1.0 will focus on use for production and feature completeness.

## Origami-μ

XQuery 3.1 introduced array and we already got maps XQuery 3.0. These are non-XML datastructures and are closer to JSON-like data structures.

Using this module you can create XML structures (and possibly JSON too) using arrays and maps. I will refer to the structures as μ-nodes ("mu-nodes").

Here's a very concise summary.

    μ:xml(['div']) 
    => <div/>
    
    μ:xml(['div', map { 'class': 'content'}])
    => <div class="content"/>
    
    μ:xml(['div', 'hello'])
    => <div>hello</div>
    
    μ:xml(['div', map { 'class': 'content'}, 'hello'])
    => <div class="content">hello</div>

There's also a special case that comes in handy with mixed content and when
you cannot have a wrapping element.

    μ:xml([(), 'hello, ', ['b', 'world'], '!'])
    => hello, <b>world</b>!

But when there is an outer element you may not have to use this special case.

    μ:xml(['p', 'hello, ', ['b', 'world'], '!'])
    => <p>hello, <b>world</b>!</p>

Origami-ω makes use of μ-nodes but users can still use regular XML-nodes or mix them with μ-nodes.

Some of the benefits of μ-nodes:

- More compact to write
- Use array/map transformation techniques
- Embedding anonymous or partial functions
- Use different serialization functions (to XML but also to JSON I hope)

For more information see the [wiki](TODO).

## Origami-ω

- Transform nodes using XSLT-style transformations.
- Extract nodes using composable selectors which are XPath expressions or XQuery functions.
- Build composable templates for rendering HTML views or XML.
- Combine it with Origami-μ templates.

> TODO

## Requirements

- BaseX 8.2

Other XML databases after 1.0.

## Getting started

- Some tutorials can be found on my [blog][blog].
- The [demo web-application](https://github.com/xokomola/fold-origami-app) contains demos for [Origami](https://github.com/xokomola/origami) using the [Fold](https://github.com/xokomola/fold) routing library.
- For documentation see the [wiki][wiki].
- The [test][tests] subdirectory contains the unit tests.

Run the unit tests:

    basex -t test

### Import

To use Origami-ω transformers import the `om.xqm` module.

    import module namespace ω = 'http://xokomola.com/xquery/origami/ω'
      at 'origami/om.xqm';

To use Origami-μ transformers import the `mu.xqm` module.

    import module namespace μ = 'http://xokomola.com/xquery/origami/μ'
      at 'origami/mu.xqm';

Of course, you can use any other namespace prefix if you feel the
greek characters are too awkward or cumbersome to type. In that case I suggest you use `om` and `mu` respectively.

[examples]: https://github.com/xokomola/origami/tree/master/examples
[tests]: https://github.com/xokomola/origami/tree/master/test
[blog]: http://xokomola.com/
[wiki]: https://github.com/xokomola/origami/wiki

