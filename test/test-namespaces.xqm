xquery version "3.1";

(:~
 : Tests for namespace functions.
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami'
    at '../origami.xqm'; 

declare %unit:test function test:ns-map()
{
    let $ns := o:ns-map()
    return
        unit:assert-equals($ns?html,'http://www.w3.org/1999/xhtml',
            "XHTML namespace is in default namespace map"
        ),

    let $ns := o:ns-map()
    return
        unit:assert-equals($ns?x,(),
            "X namespace is not in default namespace map"
        ),

    let $ns := o:ns-map(map { 'x': 'foobar' })
    return
        unit:assert-equals($ns?x,'foobar',
            "X namespace is in the namespace map"
        ),

    let $ns := o:ns-map(map { 'html': 'foobar' })
    return
        unit:assert-equals($ns?html,'foobar',
            "XHTML is mapped to foobar"
        )
};

(:~
 : A document is _normal_ (or _in namespace-normal form_) if all
 : namespace declarations appear on the root element and it is
 : not psychotic.  (A borderline document with all namespace 
 : declarations in the same place is automatically psychotic;
 : a neurotic document with this property would be illegal according
 : to the Namespaces REC.)
 :)
declare variable $test:normal := 
    <foo xmlns="foo" xmlns:x="bar"><x:bar foo="bar"/></foo>;

(:~
 : It's not always possible to produce normal documents -- the producer
 : might not know all of the relevant namespaces at the time it emits
 : the root element start-tag -- so a weaker definition is useful:
 : A document is _sane_ if it is neither neurotic nor borderline.
 :)
declare variable $test:sane := 
    <foo xmlns="foo"><x:bar xmlns:x="bar" foo="bar"/></foo>;

(:~
 : Let's say that an XML document is _neurotic_ if it maps the same
 : namespace prefix to two different namespace URIs at different
 : points.  Neurosis makes it necessary for XML processors to
 : work with {URI+localname} pairs instead of GIs, and to keep
 : track of the namespace environment at each point in the tree
 : if there are QNames-in-content.  If it weren't for neurosis,
 : applications could use a single namespace map that applied to
 : the entire document.
 :)
declare variable $test:neurotic :=
    <x:foo xmlns:x="foo">
        <x:bar xmlns:x="bar"/>
    </x:foo>;

(:~
 : Conversely, a document is _borderline_ if it maps two different
 : namespace prefixes to the same namespace URI.  Borderline documents
 : complicate reserialization: the choice of which prefix to
 : use for a particular {URI+localname} pair depends on its
 : position in the tree.
 :)
declare variable $test:borderline :=
    <x:foo xmlns:x="foo">
        <y:bar xmlns:y="foo"/>
    </x:foo>;

(:~
 : A document is _psychotic_ if it maps two different namespace prefixes
 : to the same URI _in the same scope_.  Psychosis presents an even
 : bigger difficulty for reserialization: now applications must keep
 : track of the original prefix as well as the {URI+localname} pair.
 :)
declare variable $test:psychotic :=
    <x:foo xmlns:x="foo" xmlns:y="foo" y:bar="bar"/>;

(:~
 : This document suffers from multiple disorders.
 :)
declare variable $test:psychotic-borderline-neurotic :=
    <x:foo xmlns:x="foo" xmlns:y="foo" y:bar="bar">
        <x:foo xmlns:y="bar" xmlns:z="foo" z:foo="bar"/>
    </x:foo>;

(:~
 : This document redefines default namespace on child nodes.
 : A sane approach probably only returns the namespace from
 : the highest node. 
 :)
declare variable $test:remap-default-ns :=
  <foo xmlns="foo">
    <bar xmlns="bar"/>
  </foo>;

declare %unit:test function test:remap-default-ns()
{
    unit:assert-equals(
        o:ns-map($test:remap-default-ns),
        map { '': 'foo' },
        'A weird XML document.'
    )
};

declare %unit:test function test:normal-xml()
{
    unit:assert-equals(
        o:ns-map($test:sane),
        map { '': 'foo', 'x': 'bar' },
        'A sane XML document.'
    )
};

declare %unit:test function test:sane-xml()
{
    unit:assert-equals(
        o:ns-map($test:sane),
        map { '': 'foo', 'x': 'bar' },
        'A sane XML document.'
    )
};

declare %unit:test function test:insane-xml()
{
    unit:assert-equals(
        o:ns-map($test:neurotic),
        map { 'x': 'foo' },
        'A neurotic XML maps the same namespace prefix to two different 
         namespace URIs at different points.'
    ),
    
    unit:assert-equals(
        o:ns-map($test:borderline),
        map { 'x': 'foo', 'y': 'foo' },
        'A borderline XML maps two different namespace prefixes to the same 
        namespace URI.'
    ),

    unit:assert-equals(
        o:ns-map($test:psychotic),
        map { 'x': 'foo', 'y': 'foo' },
        'A psychotic XML maps two different URIs to the same prefix.'
    ),

    unit:assert-equals(
        o:ns-map($test:psychotic-borderline-neurotic),
        map { 'x': 'foo', 'y': 'foo', 'z': 'foo' },
        'A mixture of insanity.'
    )
};

declare %unit:test function test:ns-builder()
{
    let $xf := o:ns-builder(o:ns-map())
    return
        unit:assert-equals(
            $xf?ns?html,
            'http://www.w3.org/1999/xhtml',
            'Transformer has XHTML namespace URI'
        ),
        
    let $xf := o:ns-builder($test:sane)
    return
        unit:assert-equals(
            $xf?ns,
            map { '': 'foo', 'x': 'bar' },
            'Transformer has sane XML namespace map'
        ),

    let $xf := o:ns-builder(o:ns-builder(), map:merge((o:ns-map(), o:ns-map($test:sane))))
    return (
        unit:assert-equals(
            $xf?ns?html,
            'http://www.w3.org/1999/xhtml',
            'Transformer is composed of default namespaces and XML namespaces'
        ),
        unit:assert-equals(
            $xf?ns?x,
            'bar',
            'Transformer has bar namespace'
        ),
        unit:assert-equals(
            $xf?ns(''),
            'foo',
            'Transformer has foo namespace'
        )
    )
};

declare %unit:test function test:default-ns()
{
    unit:assert-equals(
        o:default-ns(map {}, 'foo')(''),
        'foo',
        'Default namespace foo'
    ),

    unit:assert-equals(
        o:default-ns(o:ns-map(), 'bar')(''),
        'bar',
        'Default namespace foo'
    )
};

declare %unit:test function test:default-namespace() 
{
    let $xml := o:xml(['p'])
    return
        unit:assert-equals(namespace-uri($xml), '')
    ,
    let $xml := o:xml(['h:p'], o:ns-builder(o:ns-map('h')))
    return
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml')
    ,
    let $xml := o:xml(['p'], o:ns-builder(o:default-ns('http://foobar')))
    return
        unit:assert-equals(namespace-uri($xml), 'http://foobar')
    ,
    let $xml := o:xml(['h:x',['p']], o:ns-builder(o:default-ns(o:ns-map(), 'http://foobar')))
    return (
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml'),
        (: default is set to a uri so we cannot just use $xml/p to get at the child element :)
        unit:assert-equals(namespace-uri($xml/*[1]), 'http://foobar')
    )
    ,
    let $xml := o:xml(['h:x',['p']], o:ns-builder(o:default-ns(o:ns-map(), '')))
    return (
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml'),
        unit:assert-equals(namespace-uri($xml/p), '')
    )
};

(: TODO: default ns prefixes are present in the result :)
declare %unit:test function test:no-extra-namespaces-in-result()
{
      unit:assert-equals(
        in-scope-prefixes(o:xml(['x'])),
        ('xml')
      )  
};

declare %unit:test function test:prefixes() 
{
    let $xml := o:xml(['p'])
    return
        unit:assert-equals(prefix-from-QName(node-name($xml)), ())
    ,
    let $xml := o:xml(['p'], o:ns-builder(o:default-ns('http://www.w3.org/1999/xhtml')))
    return (
        unit:assert-equals(prefix-from-QName(node-name($xml)), ()),
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml')
    ),
    let $xml := o:xml(['h:p'], o:ns-builder(o:default-ns(o:ns-map(), 'http://www.w3.org/1999/xhtml')))
    return
        unit:assert-equals(prefix-from-QName(node-name($xml)), ())
    ,
    let $xml := o:xml(['x:p'],o:ns-builder(map { 'x': 'http://foobar' } => o:default-ns('http://foobar')))
    return
        unit:assert-equals(prefix-from-QName(node-name($xml)), ())
    ,
    let $xml := o:xml(['x:p'], o:ns-builder(map { 'x': 'http://foobar' }))
    return
        unit:assert-equals(prefix-from-QName(node-name($xml)), 'x')
};

declare %unit:test function test:mixed-namespaces()
{
    let $xml := o:xml(
        ['app:foo', ['atom:bar'], ['atom:bar'], ['category']], 
        o:ns-builder(o:ns-map()))
    return (
        unit:assert-equals(prefix-from-QName(node-name($xml)), 'app'),
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/2007/app'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[1])), 'atom'),
        unit:assert-equals(namespace-uri($xml/*[1]), 'http://www.w3.org/2005/Atom'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[3])), ()),
        unit:assert-equals(namespace-uri($xml/*[3]), '')        
    ),
    let $xml := o:xml(
        ['app:foo', ['atom:bar'], ['atom:bar'], ['category']], 
        o:ns-builder(o:ns-map() 
        => o:default-ns('http://www.w3.org/2007/app')))
    return (
        unit:assert-equals(prefix-from-QName(node-name($xml)), ()),
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/2007/app'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[1])), 'atom'),
        unit:assert-equals(namespace-uri($xml/*[1]), 'http://www.w3.org/2005/Atom'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[3])), ()),
        unit:assert-equals(namespace-uri($xml/*[3]), 'http://www.w3.org/2007/app')         
    ),
    let $xml := o:xml(
        ['app:foo', ['atom:bar'], ['atom:bar'], ['category']], 
        o:ns-builder(o:ns-map()
        => o:default-ns('http://www.w3.org/2005/Atom')))
    return (
        unit:assert-equals(prefix-from-QName(node-name($xml)), 'app'),
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/2007/app'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[1])), ()),
        unit:assert-equals(namespace-uri($xml/*[1]), 'http://www.w3.org/2005/Atom'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[3])), ()),
        unit:assert-equals(namespace-uri($xml/*[3]), 'http://www.w3.org/2005/Atom')         
    ),    
    let $xml := o:xml(
        ['app:foo', ['x:bar'], ['atom:bar'], ['category']], 
        o:ns-builder(map { 
            'x': 'http://www.w3.org/2005/Atom',
            'atom': 'http://www.w3.org/2005/Atom',
            'app': 'http://www.w3.org/2007/app' }
        => o:default-ns('http://www.w3.org/2005/Atom')))
    return (
        unit:assert-equals(prefix-from-QName(node-name($xml)), 'app'),
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/2007/app'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[1])), ()),
        unit:assert-equals(namespace-uri($xml/*[1]), 'http://www.w3.org/2005/Atom'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[2])), ()),
        unit:assert-equals(namespace-uri($xml/*[1]), 'http://www.w3.org/2005/Atom'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[3])), ()),
        unit:assert-equals(namespace-uri($xml/*[3]), 'http://www.w3.org/2005/Atom')         
    )
};
