xquery version "3.1";

(:~
 : Tests for μ-templates
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami'
    at '../origami.xqm'; 

declare %unit:test %unit:ignore function test:default-namespace() 
{
    let $xml := o:xml(['p'])
    return
        unit:assert-equals(namespace-uri($xml), '')
    ,
    let $xml := o:xml(['h:p'])
    return
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml')
    ,
    let $xml := o:xml(['p'], o:qname-resolver(map {}, 'http://foobar'))
    return
        unit:assert-equals(namespace-uri($xml), 'http://foobar')
    (: ,
    let $xml := o:xml(['h:x',['p']], o:qname-resolver(o:ns-map(), 'http://foobar'))
    return (
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml'),
        (: default is set to a uri so we cannot just use $xml/p to get at the child element :)
        unit:assert-equals(namespace-uri($xml/*[1]), 'http://foobar')
    )
    ,
    let $xml := o:xml(['h:x',['p']], o:qname-resolver(o:ns-map(), ''))
    return (
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml'),
        unit:assert-equals(namespace-uri($xml/p), '')
    ) :)
};

declare %unit:test %unit:ignore function test:prefixes() 
{
    let $xml := o:xml(['p'])
    return
        unit:assert-equals(prefix-from-QName(node-name($xml)), ())
    (:,
    let $xml := o:xml(['h:p'])
    return
        unit:assert-equals(prefix-from-QName(node-name($xml)), 'h')
    ,
    let $xml := o:xml(['p'], o:qname-resolver(o:ns-map(), 'http://www.w3.org/1999/xhtml'))
    return (
        unit:assert-equals(prefix-from-QName(node-name($xml)), ()),
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml')
    ),
    let $xml := o:xml(['h:p'], o:qname-resolver(o:ns-map(), 'http://www.w3.org/1999/xhtml'))
    return
        unit:assert-equals(prefix-from-QName(node-name($xml)), ())
    ,
    let $xml := o:xml(['x:p'], o:qname-resolver(o:ns-map(map { 'x': 'http://foobar' }), 'http://foobar'))
    return
        unit:assert-equals(prefix-from-QName(node-name($xml)), ())
    ,
    let $xml := o:xml(['x:p'], o:qname-resolver(o:ns-map(map { 'x': 'http://foobar' })))
    return
        unit:assert-equals(prefix-from-QName(node-name($xml)), 'x')
    :)
};

declare %unit:test function test:mixed-namespaces()
{
    true()
     (: let $xml := o:xml(
        ['app:foo', ['atom:bar'], ['atom:bar'], ['category']], 
        o:qname-resolver(o:ns-map()))
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
        o:qname-resolver(o:ns-map(), 'http://www.w3.org/2007/app'))
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
        o:qname-resolver(o:ns-map(), 'http://www.w3.org/2005/Atom'))
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
        o:qname-resolver(o:ns-map(map { 'x': 'http://www.w3.org/2005/Atom' }), 'http://www.w3.org/2005/Atom'))
    return (
        unit:assert-equals(prefix-from-QName(node-name($xml)), 'app'),
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/2007/app'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[1])), ()),
        unit:assert-equals(namespace-uri($xml/*[1]), 'http://www.w3.org/2005/Atom'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[2])), ()),
        unit:assert-equals(namespace-uri($xml/*[1]), 'http://www.w3.org/2005/Atom'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[3])), ()),
        unit:assert-equals(namespace-uri($xml/*[3]), 'http://www.w3.org/2005/Atom')         
    )    :)
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

declare variable $test:psychotic-borderline-neurotic :=
    <x:foo xmlns:x="foo" xmlns:y="foo" y:bar="bar">
        <x:foo xmlns:y="bar" xmlns:z="foo" z:foo="bar"/>
    </x:foo>;

declare %unit:test function test:neurotic()
{
    unit:assert-equals(
        o:ns-map-from-nodes($test:neurotic),
        map { 'x': 'foo' },
        "A neurotic XML maps the same namespace prefix to two different namespace URIs
         at different points."
    )
};

declare %unit:test function test:borderline()
{
    unit:assert-equals(
        o:ns-map-from-nodes($test:borderline),
        map { 'x': 'foo', 'y': 'foo' },
        "A borderline XML maps two different namespace prefixes to the same namespace
        URI."
    )
};

declare %unit:test function test:psychotic()
{
    unit:assert-equals(
        o:ns-map-from-nodes($test:psychotic),
        map { 'x': 'foo', 'y': 'foo' },
        "A psychotic XML maps two different URIs to the same prefix."
    )
};

declare %unit:test function test:psychotic-borderline-neurotic()
{
    unit:assert-equals(
        o:ns-map-from-nodes($test:psychotic-borderline-neurotic),
        map { 'x': 'foo', 'y': 'foo', 'z': 'foo' },
        "A mixture of insanity."
    )
};