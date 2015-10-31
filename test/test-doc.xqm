xquery version "3.1";

(:~
 : Tests for μ-documents
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami'
    at '../origami.xqm'; 

declare %unit:test function test:doc() 
{
    unit:assert-equals(
        o:doc(()),
        (),
        "No document"
    ),

    unit:assert-equals(
        o:doc(attribute x { 10 }),
        map:entry('x','10'),
        "An attribute map entry"
    ),

    unit:assert-equals(
        o:doc((attribute x { 10 },attribute y { 20 })),
        (map:entry('x','10'), map:entry('y','20')),
        "A sequence of map entries"
    ),
    
    unit:assert-equals(
        o:doc("foo"),
        "foo",
        "Simple string node"
    ),
    
    unit:assert-equals(
        o:doc(10),
        10,
        "Simple integer node"
    ),

    unit:assert-equals(
        o:doc((10,"foo")),
        (10, "foo"),
        "Simple atomic node sequence"
    ),

    unit:assert-equals(
        o:doc(<foo/>),
        ['foo'],
        "XML node"
    ),

    unit:assert-equals(
        o:doc((<foo/>, <bar/>)),
        (['foo'], ['bar']),
        "XML nodes"
    ),

    unit:assert-equals(
        o:doc((<foo/>, 10, <bar/>)),
        (['foo'], 10, ['bar']),
        "XML nodes"
    ),

    unit:assert-equals(
        o:doc(<foo x="10" y="20"/>),
        ['foo', map { 'x': '10', 'y': '20' }],
        "XML node with attributes"
    ),

    unit:assert-equals(
        o:doc(<foo x="10" y="20">bar</foo>),
        ['foo', map { 'x': '10', 'y': '20' }, "bar"],
        "XML node with attributes and text content"
    ),
    
    unit:assert-equals(
        o:doc(<foo x="10" y="20">bar <b>baz</b></foo>),
        ['foo', map { 'x': '10', 'y': '20' }, "bar ", ["b", "baz"]],
        "XML node with attributes and mixed content"
    ),

    unit:assert-equals(
        o:doc(<test:foo/>),
        ['test:foo'],
        "Namespaces, namespace URI is not kept, these have to be provided when serializing (if needed)"
    ),
    
    unit:assert-equals(
        o:doc(<test:foo o:bar="10"/>),
        ['test:foo', map { 'o:bar': '10' }],
        "Namespaces, attributes"
    )
};

declare %unit:test function test:doc-data()
{
    unit:assert-equals(
        o:doc(['a', 10]),
        ['a', 10],
        "Arrays are not changed"
    ),

    unit:assert-equals(
        o:doc(map { 'a': 10, 'b': '20' }),
        map { 'a': 10, 'b': '20' },
        "Maps are not changed"
    )
};

declare %unit:test function test:doc-rules()
{
    unit:assert-equals(
        o:doc(<test:foo bar="10"/>, 
            o:builder(
                map { 'test:foo': 'a-function' }
            )
        ),
        ['test:foo', map { 'bar': '10', '@': 'a-function'}],
        "Element handler"
    ),
    
    unit:assert-equals(
        o:doc(<test:foo bar="10"><p/><x/></test:foo>, 
            o:builder(
                map { 'test:foo': 'a-function', 'x': 'another-function' }
            )
        ),
        ['test:foo', map { 'bar': '10', '@': 'a-function'},
          ['p'], ['x', map { '@': 'another-function'}]
        ],
        "Element handler nested"
    )

};

declare function test:dir($p) { concat(file:base-dir(), string-join($p,'/')) };
declare function test:html($f) { test:dir(('html',$f)) };

declare %unit:test function test:whitespace()
{
    unit:assert-equals(
        o:doc(o:read-html(test:html('test004.html'))),
        <html/>
    )
};
