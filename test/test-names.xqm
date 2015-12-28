xquery version "3.1";

(:~
 : Tests for name resolvers and namespace related functions.
 :
 : - o:qname
 : - o:name
 : - o:qname-resolver
 : - o:name-resolver
 : - o:ns-map
 : - o:ns
 : - o:default-ns
 : - o:ns-builder
 : - o:xml (name related tests)
 :)

module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami'
    at '../origami.xqm'; 

declare %unit:test function test:qname_1()
{
    unit:assert-equals(
        o:qname('x'), 
        xs:QName('x')
    )
};

declare %unit:test function test:qname_1-generated-ns-uri()
{
    unit:assert-equals(
        o:qname('x:y'), 
        QName('urn:x-prefix:x', 'y'),
        "Generate prefix for unknown namespaces"
    )
};

declare %unit:test("expected", "err:FOCA0002") function test:qname_1-lexical-error()
{
    unit:assert-equals(
        o:qname('1y'), 
        xs:QName('x'),
        "Cannot cast to xs:anyURI: '1y'"
    )
};

declare %unit:test function test:qname_2()
{
    unit:assert-equals(
        o:qname('x:y', map { 'x': 'foo' }), 
        QName('foo','x:y')
    )
};

declare %unit:test function test:qname_2-n-ns-uri-generated()
{
    unit:assert-equals(
        o:qname('x:y', map { 'y': 'foo' }), 
        QName('urn:x-prefix:x','x:y')
    )
};

declare %unit:test function test:qname_2-default-ns()
{
    unit:assert-equals(
        o:qname('y', map { '': 'foo' }), 
        QName('foo','y')
    )
};

declare %unit:test function test:qname_2-with-fn()
{
    unit:assert-equals(
        o:qname('x', function($x) { QName((), upper-case($x)) }), 
        QName((), 'X')
    )
};

declare %unit:test("expected", "err:XPTY0004") function test:qname_2-with-fn-not-qname-err()
{
    unit:assert-equals(
        o:qname('x', function($x) { upper-case($x) }), 
        QName((), 'X')
    )
};

declare %unit:test("expected", "o:invalid-argument") function test:qname_2-with-fn-resolver-err()
{
    unit:assert-equals(
        o:qname('x', [1,2,3]), 
        QName((), 'X')
    )
};

declare %unit:test function test:name_2-with-map()
{
    unit:assert-equals(
        o:name('x', map { 'x': 'foo' }), 
        'foo'
    ),

    unit:assert-equals(
        o:name('x', map { 'y': 'foo' }), 
        'x'
    )
};

(: TODO: what to do with arrays? :)
declare %unit:test function test:name_2-with-fn()
{
    unit:assert-equals(
        o:name('x', function($x) { upper-case($x) }), 
        'X'
    ),

    unit:assert-equals(
        o:name('x', function($x) { () }), 
        'x'
    )
};

declare %unit:test function test:qname-resolver_1()
{
    unit:assert-equals(
        o:qname-resolver(function($name) { QName((),'x') })('foo'),
        QName((), 'x'),
        "Resolve string names using a resolver function that returns QNames"
    ),

    unit:assert-equals(
        o:qname-resolver(map { '': 'x' })('foo'),
        QName('x', 'foo'),
        "Resolve string names using a namespace map"
    )    
};

declare %unit:test function test:name-resolver_1()
{
    unit:assert-equals(
        o:name-resolver(function($name) { upper-case($name) })('foo'),
        'FOO'
    ),

    unit:assert-equals(
        o:name-resolver(map { 'foo': 'x' })('foo'),
        'x'
    )    
};

declare %unit:test function test:ns_1()
{
    unit:assert-equals(
        o:ns((map { 'x': 'urn:foo' }, <x:foo xmlns:x="urn:bar"/>)),
        map {
            'x': 'urn:bar'
        }
    ),
    
    unit:assert-equals(
        o:ns((<foo xmlns="urn:foo"/>, <bar xmlns="urn:bar"/>)),
        map { 
            '': 'urn:bar'
        }
    )

};

declare %unit:test("expected", "o:invalid-argument") function test:ns_1-arg-err()
{
    unit:assert-equals(
        o:ns(1),
        'x',
        "Second argument is not valid"
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

declare %unit:test function test:ns_1-default-ns()
{
    unit:assert-equals(
        o:ns($test:remap-default-ns),
        map { '': 'foo' },
        "A weird XML document."
    )
};

declare %unit:test function test:ns_1-normal-xml()
{
    unit:assert-equals(
        o:ns($test:sane),
        map { '': 'foo', 'x': 'bar' },
        "A sane XML document."
    )
};

declare %unit:test function test:ns_1-sane-xml()
{
    unit:assert-equals(
        o:ns($test:sane),
        map { '': 'foo', 'x': 'bar' },
        "A sane XML document."
    )
};

(:~
 : This test illustrates how `o:ns` behaves on insane XML nodes.
 :)
declare %unit:test function test:ns_1-insane-xml()
{
    unit:assert-equals(
        o:ns($test:neurotic),
        map { 'x': 'foo' },
        "A neurotic XML maps the same namespace prefix to two different 
         namespace URIs at different points."
    ),
    
    unit:assert-equals(
        o:ns($test:borderline),
        map { 'x': 'foo', 'y': 'foo' },
        "A borderline XML maps two different namespace prefixes to the same 
         namespace URI."
    ),

    unit:assert-equals(
        o:ns($test:psychotic),
        map { 'x': 'foo', 'y': 'foo' },
        "A psychotic XML maps two different URIs to the same prefix."
    ),

    unit:assert-equals(
        o:ns($test:psychotic-borderline-neurotic),
        map { 'x': 'foo', 'y': 'foo', 'z': 'foo' },
        "Multiple disorders."
    )
};

declare %unit:test function test:default-namespace() 
{
    let $xml := o:xml(['p'])
    return
        unit:assert-equals(namespace-uri($xml), '')
    ,
    let $xml := o:xml(['h:p'], o:ns(['h', $o:ns?html]))
    return
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml')
    ,
    let $xml := o:xml(['p'], o:ns(['', 'http://foobar']))
    return
        unit:assert-equals(namespace-uri($xml), 'http://foobar')
    ,
    let $xml := o:xml(['h:x',['p']], o:ns((['h', $o:ns?html], ['', 'http://foobar'])))
    return (
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml'),
        (: default is set to a uri so we cannot just use $xml/p to get at the child element :)
        unit:assert-equals(namespace-uri($xml/*[1]), 'http://foobar')
    )
    ,
    let $xml := o:xml(['h:x',['p']], o:ns(['h', $o:ns?html]))
    return (
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml'),
        unit:assert-equals(namespace-uri($xml/p), '')
    )
};

declare %unit:test function test:ns-builder()
{
    unit:assert-equals(
        o:ns-builder(['html', $o:ns?html])?ns?html,
        'http://www.w3.org/1999/xhtml',
        "Builder has XHTML namespace URI"
    ),
        
    unit:assert-equals(
        o:ns-builder($test:sane)?ns,
        map { '': 'foo', 'x': 'bar' },
        "Transformer has sane XML namespace map"
    )
};

declare %unit:test function test:no-extra-namespaces-in-result()
{
      unit:assert-equals(
        in-scope-prefixes(o:xml(['x'])),
        ('xml')
      )  
};

declare %unit:test function test:all-default-bound-prefixes-on-document-element()
{
      unit:assert(
        every $prefix in in-scope-prefixes(o:xml(['x'],  $o:ns))
        satisfies $prefix = ('xml','origami','html','svg','xsl','xs')
      )  
};

