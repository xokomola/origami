xquery version "3.1";

(:~
 : Tests for μ-documents
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu' at '../mu.xqm'; 

declare %unit:test function test:doc() 
{
    unit:assert-equals(
        μ:doc(()),
        (),
        "No document"
    ),
    
    unit:assert-equals(
        μ:doc("foo"),
        "foo",
        "Simple string node"
    ),
    
    unit:assert-equals(
        μ:doc(10),
        10,
        "Simple integer node"
    ),

    unit:assert-equals(
        μ:doc((10,"foo")),
        (10, "foo"),
        "Simple atomic node sequence"
    ),

    unit:assert-equals(
        μ:doc(<foo/>),
        ['foo'],
        "XML node"
    ),

    unit:assert-equals(
        μ:doc((<foo/>, <bar/>)),
        (['foo'], ['bar']),
        "XML nodes"
    ),

    unit:assert-equals(
        μ:doc((<foo/>, 10, <bar/>)),
        (['foo'], 10, ['bar']),
        "XML nodes"
    ),

    unit:assert-equals(
        μ:doc(<foo x="10" y="20"/>),
        ['foo', map { 'x': '10', 'y': '20' }],
        "XML node with attributes"
    ),

    unit:assert-equals(
        μ:doc(<foo x="10" y="20">bar</foo>),
        ['foo', map { 'x': '10', 'y': '20' }, "bar"],
        "XML node with attributes and text content"
    ),
    
    unit:assert-equals(
        μ:doc(<foo x="10" y="20">bar <b>baz</b></foo>),
        ['foo', map { 'x': '10', 'y': '20' }, "bar ", ["b", "baz"]],
        "XML node with attributes and mixed content"
    ),

    unit:assert-equals(
        μ:doc(<test:foo/>),
        ['test:foo'],
        "Namespaces, namespace URI is not kept, these have to be provided when serializing (if needed)"
    ),
    
    unit:assert-equals(
        μ:doc(<test:foo μ:bar="10"/>),
        ['test:foo', map { 'μ:bar': '10' }],
        "Namespaces, attributes"
    )
};

declare %unit:test function test:doc-data()
{
    unit:assert-equals(
        μ:doc(['a', 10]),
        ['a', 10],
        "Arrays are not changed"
    ),

    unit:assert-equals(
        μ:doc(map { 'a': 10, 'b': '20' }),
        map { 'a': 10, 'b': '20' },
        "Maps are not changed"
    )
};

declare %unit:test function test:doc-rules()
{
    unit:assert-equals(
        μ:doc(<test:foo bar="10"/>, 
            map { 'test:foo': 'a-function' }),
        ['test:foo', map { 'bar': '10', 'μ:fn': 'a-function'}],
        "Element handler"
    ),
    
    unit:assert-equals(
        μ:doc(<test:foo bar="10"><p/><x/></test:foo>, 
            map { 'test:foo': 'a-function', 'x': 'another-function' }),
        ['test:foo', map { 'bar': '10', 'μ:fn': 'a-function'},
          ['p'], ['x', map { 'μ:fn': 'another-function'}]
        ],
        "Element handler nested"
    )

};
