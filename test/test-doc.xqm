xquery version "3.1";

(:~
 : o:doc tests
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

declare %unit:test function test:doc-repr()
{
    unit:assert-equals(
        o:doc-repr(['foo', function($n,$d){1}, 'a', 10]),
        ['foo', 'fn#2','a',10],
        "Inline handler"
    ),

    unit:assert-equals(
        o:doc-repr(['foo', [function($n,$d){1}, 'a',10]]),
        ['foo', ['fn#2','a',10]],
        "Inline handler with arguments"
    ),

    unit:assert-equals(
        o:doc-repr(['foo', map { '@': function($n,$d){1}}, "bar"]),
        ['foo', map { '@': "fn#2" }, "bar"],
        "Element handler"
    ),

    unit:assert-equals(
        o:doc-repr(['foo', map { '@': [function($n,$d) {1},1,2,3]}, "bar"]),
        ['foo', map { '@': ["fn#2",1,2,3] }, "bar"],
        "Element handler with arguments"
    ),

    unit:assert-equals(
        o:doc-repr(['foo', map { 'x': function($n,$d){1}}, "bar"]),
        ['foo', map { 'x': "fn#2" }, "bar"],
        "Attribute handler"
    ),

    unit:assert-equals(
        o:doc-repr(['foo', map { 'x': [function($n,$d) {1},1,2,3]}, "bar"]),
        ['foo', map { 'x': ["fn#2",1,2,3] }, "bar"],
        "Attribute handler with arguments"
    )
};

declare %unit:test("expected", "Q{http://xokomola.com/xquery/origami}unwellformed") 
function test:unwellformed-free-attributes()
{
    unit:assert-equals(
        o:doc(attribute x { 10 }),
        (),
        "Free attribute nodes are not supported"
    )
};

declare %unit:test("expected", "Q{http://xokomola.com/xquery/origami}unwellformed") 
function test:unwellformed-tag-not-a-string()
{
    unit:assert-equals(
        o:doc([10, 10]),
        (),
        "First item of an element node must be a string"
    )
};

declare %unit:test("expected", "Q{http://xokomola.com/xquery/origami}unwellformed") 
function test:unwellformed-attribute-name-not-a-string()
{
    unit:assert-equals(
        o:doc(["foo", map { 1: 'bar'}]),
        (),
        "Attribute name must be a string"
    )
};

declare %unit:test("expected", "Q{http://xokomola.com/xquery/origami}unwellformed") 
function test:unwellformed-map-in-attribute-position()
{
    unit:assert-equals(
        o:doc(map { 'a': 10, 'b': '20' }),
        (),
        "Maps are only allowed in attribute position"
    )
};

declare %unit:test function test:doc-builder-add-handlers()
{
    unit:assert-equals(
        o:doc-repr(
            o:doc(
                <test:foo bar="10"/>, 
                o:builder(
                    map { 'test:foo': function(){1} }
                )
            )
        ),
        ['test:foo', map { 'bar': '10', '@': 'fn#2' }],
        "Element handler (0-arity handlers are wrapped in 2-arity handlers"
    ),
    
    unit:assert-equals(
        o:doc-repr(
            o:doc(
                <test:foo bar="10"><p/><x/></test:foo>, 
                o:builder(
                    map { 
                        'test:foo': function(){1}, 
                        'x': function(){1} 
                    }
                )
            )
        ),
        ['test:foo', map { 'bar': '10', '@': 'fn#2' }, ['p'], ['x', map { '@': 'fn#2' }]],
        "Multiple element handlers"
    ),
    
    unit:assert-equals(
        o:doc-repr(
            o:doc(
                <test:foo bar="10"><foo bar="20"/></test:foo>, 
                o:builder(
                    map { '@bar': function(){1} }
                )
            )
        ),
        ['test:foo', map { 'bar': 'fn#2' }, ['foo', map { 'bar': 'fn#2'}]],
        "Attribute handler"
    ),

    unit:assert-equals(
        o:doc-repr(
            o:doc(
                <test:foo bar="10"><foo bar="20"/></test:foo>, 
                o:builder(
                    map { 'test:foo@bar': function(){1} }
                )
            )
        ),
        ['test:foo', map { 'bar': 'fn#2' }, ['foo', map { 'bar': '20'}]],
        "Attribute handler"
    ),

    unit:assert-equals(
        o:doc-repr(
            o:doc(
                <test:foo bar="10"><foo bar="20"/></test:foo>, 
                o:builder(
                    map { 'foo@bar': function(){1} }
                )
            )
        ),
        ['test:foo', map { 'bar': '10' }, ['foo', map { 'bar': 'fn#2'}]],
        "Attribute handler"
    )
    
};

declare %unit:test("expected", "Q{http://xokomola.com/xquery/origami}invalid-handler") 
function test:a-string-is-not-a-valid-handler()
{
    unit:assert(
        o:doc(<test:foo bar="10"/>, 
            o:builder(
                map { 'test:foo': 'foo' }
            )
        )
    )  
};

declare %unit:test("expected", "Q{http://xokomola.com/xquery/origami}invalid-handler") 
function test:a-map-is-not-a-valid-handler()
{
    unit:assert(
        o:doc(<test:foo bar="10"/>, 
            o:builder(
                map { 'test:foo': map {} }
            )
        )
    )  
};

declare function test:dir($p) { concat(file:base-dir(), string-join($p,'/')) };
declare function test:html($f) { test:dir(('html',$f)) };

declare %unit:test function test:whitespace()
{
    unit:assert-equals(
        o:doc(o:read-html(test:html('test004.html'))),
        [
          "html",
          map {
            "lang": "en"
          },
          [
            "head",
            [
              "meta",
              map {
                "charset": "utf-8"
              }
            ],
            [
              "title",
              "title"
            ]
          ],
          [
            "body",
            [
              "p",
              "Hellö ",
              [
                "b",
                "world"
              ],
              "! "
            ]
          ]
        ]
    )
};
