# Origami

Origami is a templating library for XQuery (3.0) inspired by XSLT and the
[Enlive](https://github.com/cgrand/enlive) templating library for Clojure.
Currently it supports the [BaseX](http://basex.org) database version 8 or
higher.

## Features

- XSLT-style transformations written with plain XQuery functions using simple
  selector patterns.

## Requirements

- BaseX 8.0 or higher (currently in beta)

## Getting started

The `examples` subdirectory contains a few examples.

In code examples below I left out the namespace prefixes for clarity.

### Import

To use Origami transformers import the module.

~~~xquery
import module namespace xf = 'http://xokomola.com/xquery/origami/xform'
  at 'xform.xqm';
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

A template is a map that contains a selector and a node transformation function.

~~~xquery
$ul-tpl
  
=> map {
    'match': xf:matches('list',?),
    'fn': function ($list as element(list)) { ... }
   }
~~~

### Transformers

To create a transformer use the `xf:xform` function and pass it a sequence of
templates.

~~~xquery
declare variable $xformer := xf:xform(($ul-tpl, $li-tpl));
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
  xf:xform((
    
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
    
### Remove nodes

To remove nodes create a template that matches these nodes but instead of a node
transformation function provide an empty sequence as the second argument.

~~~xquery
declare variable $remove-x := xf:template('x', ());
~~~

### Gotchas

To be able to apply further node transformations from inside a node
transformation function you need to tell the transformer to which nodes it
should apply the transformation templates.

You can do this with the `<xf:apply>` element (or function) which is a control
element. The downside is that certain XPath expressions may not work as expected
anymore.

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
