# Origami 0.3

Origami is a templating library for XQuery (3.0) inspired by XSLT and the
[Enlive](https://github.com/cgrand/enlive) templating library for Clojure.
Currently it supports the [BaseX](http://basex.org) database version 8.0 or
higher.

IMPORTANT: This library is not yet ready for production use and will change
during the next few releases. I feel no obligation to maintain backwards
compatibility but I will try to keep this README and the [blog
posts](http://xokomola.com/) up-to-date with the latest release.

## Features

- Transform nodes using XSLT-style transformations.

- Extract nodes using composable selectors which are XPath expressions or XQuery
  functions.

## Requirements

- BaseX 8.0 or higher

Previously 7.9 worked but from 0.3 onwards you need a recent snapshot (I tested
on 2014-11-16 snapshot).

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

### Node transformers

A node transformation function has a single node argument and returns the
transformed node.

~~~xquery
declare function ul($list as element(list)) { 
  <ul>{ xf:apply($list/node()) }</ul>
};
~~~

Nodes returned by the node transformation function are copied to the result
without further transformation unless they are applied again. You can transform
child nodes using the `xf:apply` function or using the `<xf:apply/>` element.

~~~xquery
declare function li($item as element(item)) { 
  <li>
    <xf:apply>{ $item/node() }</xf:apply>
  </li> 
};
~~~

### Transformation templates

To create a transformation template use the `xf:template` function and pass it a
selector string and a node transformation function.

An element selector is the name of an element or `*`. An attribute selector
starts with a `@` followed by the name of an attribute or `*`.

~~~xquery
declare variable $ul-tpl := xf:template('list', ul#1);
declare variable $li-tpl := xf:template('item', li#1);
~~~

A template is a map that contains a selector function and a node transformation
function.

~~~xquery
$ul-tpl
  
=> map {
    'match': xf:matches(?,'list'),
    'fn': function ($list as element(list)) { ... }
   }
~~~

Supply custom match functions by passing a boolean function as the first argument.

~~~xquery
declare variable $cust-match := 
  xf:template(
    function($n) { exists($n/@x) }, ul(?));
~~~

Supply a literal result fragment as the second argument.

~~~xquery
declare variable $lit-result := 
  xf:template('*', <foo/>);
~~~

### Transformers

To create a transformer use the `xf:transform` function and pass it a sequence of
templates.

~~~xquery
declare variable $xformer := xf:transform(($ul-tpl, $li-tpl));
~~~

A transformer is a function with a single node sequence argument that returns
the transformed nodes.

~~~xquery
$xformer(
  <list>
    <item>item 1</item>
    <item>item 2</item>
  </list>)

=> <ul>
     <li>item 1</li>
     <li>item 2</li>
   </ul>
~~~

Instead of named functions you can define templates using anonymous functions
as node transformers.

~~~xquery
declare variable $xformer :=
  xf:transform((
    
      xf:template('list', 
        function ($list as element(list)) { 
          <ul>{ xf:apply($list/node()) }</ul> 
        }),
          
      xf:template('item',
        function ($item as element(item)) { 
          <li>{ xf:apply($item/node()) }</li>
        })        
  ));
~~~

As a shortcut you can provide both the transformation templates and the
input nodes in one call to `xf:xform`.

~~~xquery
xf:transform(xf:template('x', <y/>), <x/>)
~~~

Contrary to XSLT transformations a transformer will act like an identity
transformer when no templates are provided. This makes more sense for
a templating library.

### Remove nodes

To remove nodes create a template that matches these nodes but instead of a node
transformation function provide an empty sequence as the second argument.

~~~xquery
declare variable $remove-x := xf:template('x', ());
~~~

### Transformer gotchas

To be able to apply further node transformations from inside a node
transformation function you need to tell the transformer to which nodes it
should apply the transformation templates.

You can do this with the `<xf:apply/>` element (or same-named function) which is
a control element. The downside is that certain XPath expressions may not work
as expected anymore.

For example when looking for a node's parent you cannot use `$node/..` or
`$node/parent::*` because this may return the `xf:apply` control node instead of
the original parent of the node.

I decided that the benefits outweigh the cost. In future other control nodes may
be added and, in my opinion, this mechanism provides a relatively clean
separation between the individual node transformation function and the
transformation as a whole.

Additionally, such XPath queries can be encapsulated using helper functions that
simply overlook these `xf:*` elements.

~~~xquery
declare function parent($node) {
  $node/ancestor::*[not(self::xf:*)][1]
};
~~~


### Selectors

To create a selector use the `xf:select` function and pass it a sequence of
selectors. Selectors are used to build up Extractor functions.

~~~xquery
declare variable $li := xf:select('li');
~~~

A selector is a function that when applied to a node sequence will return
the nodes selected by the XPath expression passed in as a string.

~~~xquery
$li(
  <ul>
    <li>item 1</li>
    <li>item 2</li>
  </ul>)

=> (
     <li>item 1</li>,
     <li>item 2</li>
   )
~~~

The string selector is converted into a selector function. It interpretes the
string as an XPath expression which will be applied to the current node and all
descendants. Note that this is different from XSLT. It makes it easier to select
nodes deeply hidden in HTML soup.

Each selector may be passed a sequence of selectors. This means that selectors
can be composed of other selectors.

A selector function has the following general signature:

~~~xquery
function (node()*) as node()*
~~~

This means you can pass any function that complies with this signature. The above
example could have been written as:

~~~xquery
declare variable $li := xf:select(
    function ($nodes) {
        $nodes//li
    });
~~~

Using a sequence of selectors builds a small pipeline with transformation
capabilities.

Two such selector functions are `xf:wrap` and `xf:unwrap`. Suppose we want
to change the returned `li` elements into `list-item` elements.

~~~xquery
declare variable $li := xf:select(('li', xf:unwrap(), xf:wrap(<list-item/>)))
~~~

This will now remove the `li` element and wrap it's contents in `list-item`
elements.

~~~xquery
$li(
  <ul>
    <li>item 1</li>
    <li>item 2</li>
  </ul>)

=> (
     <list-item>item 1</list-item>,
     <list-item>item 2</list-item>
   )
~~~


### Extractors

To create an extractor use the `xf:extract` function and pass it a sequence of
selectors.

Selectors just return nodes but when combining several selectors you might get
duplicate nodes and they might be in a different order. The extractor function
will do some house-keeping by removing duplicate nodes, returning only the
outermost nodes and return them in document order.

~~~xquery
declare variable $xtract :=
  xf:extract((
    xf:select('li[@id="last"]'), 
    xf:select('li'),
    xf:select('li[@id="first"]')));
~~~

An extractor is a function with a single node sequence argument that returns
the selected nodes in document order with duplicates removed.

~~~xquery
$xtract(
  <ul>
    <li id="first">item 1</li>
    <li>item 2</li>
    <li id="last">item 3</li>
  </ul>)

=> (
     <li id="first">item 1</li>,
     <li>item 2</li>,
     <li id="last">item 3</li>,
   )
~~~


### Parsing HTML

For convenience there are two functions for loading and parsing
HTML via BaseX's `html:parse` function.

To load HTML from the web use `xf:fetch-html` with a URL.

To load HTML from the filesystem use `xf:parse-html` with a path.



