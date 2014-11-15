# Origami

Origami is a templating library for XQuery (3.0) inspired by XSLT and the
[Enlive](https://github.com/cgrand/enlive) templating library for Clojure.
Currently it supports the [BaseX](http://basex.org) database version 7.9 or
higher.

## Features

- XSLT-style transformations written with plain XQuery functions using simple
  string based match patterns or match functions.

## Requirements

- BaseX 7.9 or higher.

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

A selector is a function that when applied to a node sequence will return
the nodes selected by an XPath expression.

~~~xquery
declare variable $li := xf:select('li');
~~~

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

Note that this does not descend into the document but rather takes the
top element as the context for the XPath expression of the select.


### Extractors

An extractor is a function with a single node sequence argument that returns
the selected nodes.

~~~xquery
declare variable $xtract := xf:extract(xf:select('li'));
~~~

Contrary to a single select an extractor will traverse the whole node
structure passed into it.

~~~xquery
$xtract(
  <ul>
    <li>item 1</li>
    <li>item 2</li>
  </ul>)

=> (
     <li>item 1</li>,
     <li>item 2</li>
   )
~~~

### Extractor gotchas

An extractor returns nodes in a breadth-first order. From XSLT you may expect
this to return matched nodes in document order.

~~~xquery
declare variable $p := xf:extract(xf:select('p'));
~~~

~~~xquery
$p(
  <div>
    <p>p1</p>
    <div>
      <p>p2</p>
    </div>
    <p>p3</p>
  </div>)

=> (<p>p1</p>,<p>p3</p>,<p>p2</p>)
~~~

If you do need to select them in document order then I suggest you
rewrite the extractor like this:

~~~xquery
declare variable $p := xf:extract(xf:select('.//p'));
~~~

An extractor will remove duplicate nodes at the end of the extraction
process. Nodes that are matched by multiple times are removed.


