xquery version "3.1";

(:~
 : Tests for μ-documents
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu' at '../mu.xqm'; 

declare %unit:test function test:doc() 
{
    unit:assert-equals(
        μ:nodes(()),
        (),
        "No document"
    ),
    
    unit:assert-equals(
        μ:nodes("foo"),
        "foo",
        "Simple string node"
    ),
    
    unit:assert-equals(
        μ:nodes(10),
        10,
        "Simple integer node"
    ),

    unit:assert-equals(
        μ:nodes((10,"foo")),
        (10, "foo"),
        "Simple atomic node sequence"
    ),

    unit:assert-equals(
        μ:nodes(['a', 10]),
        ['μ:array', "a", 10],
        "An array"
    ),

    unit:assert-equals(
        μ:nodes(['μ:object', 10]),
        ['μ:object', 10],
        "A μ object will pass unmodified"
    ),

    unit:assert-equals(
        μ:nodes(map { 'a': 10, 'b': '20' }),
        ['μ:map', ['a', 10], ['b', '20']],
        "An array"
    ),

    unit:assert-equals(
        μ:nodes(<foo/>),
        ['foo'],
        "XML node"
    ),

    unit:assert-equals(
        μ:nodes((<foo/>, <bar/>)),
        (['foo'], ['bar']),
        "XML nodes"
    ),

    unit:assert-equals(
        μ:nodes((<foo/>, 10, <bar/>)),
        (['foo'], 10, ['bar']),
        "XML nodes"
    ),

    unit:assert-equals(
        μ:nodes(<foo x="10" y="20"/>),
        ['foo', map { 'x': '10', 'y': '20' }],
        "XML node with attributes"
    ),

    unit:assert-equals(
        μ:nodes(<foo x="10" y="20">bar</foo>),
        ['foo', map { 'x': '10', 'y': '20' }, "bar"],
        "XML node with attributes and text content"
    ),
    
    unit:assert-equals(
        μ:nodes(<foo x="10" y="20">bar <b>baz</b></foo>),
        ['foo', map { 'x': '10', 'y': '20' }, "bar ", ["b", "baz"]],
        "XML node with attributes and mixed content"
    ),

    unit:assert-equals(
        μ:nodes(<test:foo/>),
        ['test:foo'],
        "Namespaces, namespace URI is not kept, these have to be provided when serializing (if needed)"
    ),
    
    unit:assert-equals(
        μ:nodes(<test:foo μ:bar="10"/>),
        ['test:foo', map { 'μ:bar': '10' }],
        "Namespaces, attributes"
    )


};
