xquery version "3.1";

(:~
 : Tests for μ-templates
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu' at '../mu.xqm'; 

declare %unit:test function test:default-namespace() 
{
    let $xml := μ:xml(['p'])
    return
        unit:assert-equals(namespace-uri($xml), '')
    ,
    let $xml := μ:xml(['h:p'])
    return
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml')
    ,
    let $xml := μ:xml(['p'], μ:qname-resolver(map {}, 'http://foobar'))
    return
        unit:assert-equals(namespace-uri($xml), 'http://foobar')
    ,
    let $xml := μ:xml(['h:x',['p']], μ:qname-resolver(μ:ns(), 'http://foobar'))
    return (
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml'),
        (: default is set to a uri so we cannot just use $xml/p to get at the child element :)
        unit:assert-equals(namespace-uri($xml/*[1]), 'http://foobar')
    )
    ,
    let $xml := μ:xml(['h:x',['p']], μ:qname-resolver(μ:ns(), ''))
    return (
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml'),
        unit:assert-equals(namespace-uri($xml/p), '')
    )
};

declare %unit:test function test:prefixes() 
{
    let $xml := μ:xml(['p'])
    return
        unit:assert-equals(prefix-from-QName(node-name($xml)), ())
    ,
    let $xml := μ:xml(['h:p'])
    return
        unit:assert-equals(prefix-from-QName(node-name($xml)), 'h')
    ,
    let $xml := μ:xml(['p'], μ:qname-resolver(μ:ns(), 'http://www.w3.org/1999/xhtml'))
    return (
        unit:assert-equals(prefix-from-QName(node-name($xml)), ()),
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/1999/xhtml')
    ),
    let $xml := μ:xml(['h:p'], μ:qname-resolver(μ:ns(), 'http://www.w3.org/1999/xhtml'))
    return
        unit:assert-equals(prefix-from-QName(node-name($xml)), ())
    ,
    let $xml := μ:xml(['x:p'], μ:qname-resolver(μ:ns(map { 'x': 'http://foobar' }), 'http://foobar'))
    return
        unit:assert-equals(prefix-from-QName(node-name($xml)), ())
    ,
    let $xml := μ:xml(['x:p'], μ:qname-resolver(μ:ns(map { 'x': 'http://foobar' })))
    return
        unit:assert-equals(prefix-from-QName(node-name($xml)), 'x')
};

declare %unit:test function test:mixed-namespaces()
{
    let $xml := μ:xml(
        ['app:foo', ['atom:bar'], ['atom:bar'], ['category']], 
        μ:qname-resolver(μ:ns()))
    return (
        unit:assert-equals(prefix-from-QName(node-name($xml)), 'app'),
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/2007/app'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[1])), 'atom'),
        unit:assert-equals(namespace-uri($xml/*[1]), 'http://www.w3.org/2005/Atom'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[3])), ()),
        unit:assert-equals(namespace-uri($xml/*[3]), '')        
    ),
    let $xml := μ:xml(
        ['app:foo', ['atom:bar'], ['atom:bar'], ['category']], 
        μ:qname-resolver(μ:ns(), 'http://www.w3.org/2007/app'))
    return (
        unit:assert-equals(prefix-from-QName(node-name($xml)), ()),
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/2007/app'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[1])), 'atom'),
        unit:assert-equals(namespace-uri($xml/*[1]), 'http://www.w3.org/2005/Atom'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[3])), ()),
        unit:assert-equals(namespace-uri($xml/*[3]), 'http://www.w3.org/2007/app')         
    ),
    let $xml := μ:xml(
        ['app:foo', ['atom:bar'], ['atom:bar'], ['category']], 
        μ:qname-resolver(μ:ns(), 'http://www.w3.org/2005/Atom'))
    return (
        unit:assert-equals(prefix-from-QName(node-name($xml)), 'app'),
        unit:assert-equals(namespace-uri($xml), 'http://www.w3.org/2007/app'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[1])), ()),
        unit:assert-equals(namespace-uri($xml/*[1]), 'http://www.w3.org/2005/Atom'),
        unit:assert-equals(prefix-from-QName(node-name($xml/*[3])), ()),
        unit:assert-equals(namespace-uri($xml/*[3]), 'http://www.w3.org/2005/Atom')         
    ),    
    let $xml := μ:xml(
        ['app:foo', ['x:bar'], ['atom:bar'], ['category']], 
        μ:qname-resolver(μ:ns(map { 'x': 'http://www.w3.org/2005/Atom' }), 'http://www.w3.org/2005/Atom'))
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

