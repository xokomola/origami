xquery version '3.1';

(:~
 : Tests for generting XML nodes from Mu-nodes.
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami'
    at '../origami.xqm'; 

declare %unit:test function test:xml() 
{
    unit:assert-equals(
        o:xml('a'),
        text { 'a' },
        "A string item returns a text node"
    ),
      
    unit:assert-equals(
        o:xml(('a','b','c')),
        (text { 'a' }, text { 'b'}, text { 'c' }),
        "A sequence of string items returns a sequence of text nodes"
    ),

    unit:assert-equals(
        o:xml(['a']),
        <a/>,
        "An array with one string item returns an empty element"
    ),

    unit:assert-equals(
        o:xml(['a','hello']),
        <a>hello</a>,
        "An array with two strings returns an element with text content"
    ),
    
    unit:assert-equals(
        o:xml(['a','hello', 'world']),
        element a { text { 'hello' }, text { 'world' } },
        "An array with three strings returns an element with two text nodes."
    ),

    unit:assert-equals(
        o:xml(['a',map { 'x': 10, 'b': 'y' }]),
        <a x="10" b="y"/>,
        "An array with a string and a map returns an empty element with attributes"
    ),

    unit:assert-equals(
        o:xml(['a',map { }]),
        <a/>,
        "But with an empty map it will not output attributes"
        
    ),
    
    unit:assert-equals(
        o:xml(['a',map { 'x': 10, 'b': 'y' }, 'hello']),
        <a x="10" b="y">hello</a>,
        "An array consisting of a string, a map and a string returns an element with attributes and text content"
    ),

    unit:assert-equals(
        o:xml(['a',map { }, 'hello']),
        <a>hello</a>,
        "An array with a string, an empty map and a string returns an element with text content but no attributes"
        
    ),
    
    unit:assert-equals(
        o:xml(['a',map { 'x': 10, 'b': 'y' }, ()]),
        <a x="10" b="y"/>,
        "An empty sequence does not create an XML node"
    ),

    unit:assert-equals(
        o:xml(['a', map { }, ()]),
        <a/>,
        "An empty map and an empty sequence return an empty element"
    ),
   
    unit:assert-equals(
        o:xml(<a/>),
        <a/>,
        "An XML node will be passed through unmodified"
    ),

    unit:assert-equals(
        o:xml(['a', ['b', ['c']]]),
        <a>
            <b>
                <c/>
            </b>
        </a>,
        "Nested arrays produce nested elements"
    ),

    unit:assert-equals(
        o:xml(['a', (['b'], ['c'])]),
        <a>
            <b/>
            <c/>
        </a>,
        "Nested arrays produce nested elements (sequences are flattened)"
    ),

    unit:assert-equals(
        o:xml(['a', 'b', 'c']),
        <a>bc</a>
    ),

    unit:assert-equals(
        o:xml(['a', ('b','c')]),
        <a>{ text { 'b' }, text { 'c' }}</a>,
        "A sequence of strings will create a sequence of text nodes"
    ),

    unit:assert-equals(
        o:xml(['a', ('b','c')]),
        <a>bc</a>,
        "A sequence of strings appear as if they are concatenated"
    ),

    unit:assert-equals(
        o:xml(['a', (10,'c')]),
        <a>10c</a>,
        "Any atomic value will be returned as text node"
    ),
   
    unit:assert-equals(
        o:xml(['a', ('foo', ['b', 'bar', ['c'], 'baz'])]),
        <a>foo<b>bar<c/>baz</b></a>,
        "Mixed content"
    ),
  
    unit:assert-equals(
        o:xml(['a', (map {'x': 10}, 'foo')]),
        <a x="10">foo</a>,
        "The second item of the array may be a sequence and if the head is a map it will be used to create attributes"
    ),
    
    unit:assert-equals(
        o:xml([('a', map {'x': 10}, 'foo')]),
        <a x="10">foo</a>,
        "If the array contains one element sequence it's no different than an array of three individual items"
    )    
};

(: TODO: review these cases :)
declare %unit:test function test:complex-attribute-values()
{
    unit:assert-equals(
        o:xml(['a', map { 'x': [10,20,30] }]),
        <a>
            <x>102030</x>
        </a>,
        "An array attribute value results in an extra child element"
    ),
    
    unit:assert-equals(
        o:xml(['a', map { 'x': map { 'foo': 'bar', 'y': 10 }}]),
        <a>
            <x foo="bar" y="10"/>
        </a>,
        "A map attribute value results in an extra child element with attributes."
    ),

    unit:assert-equals(
        o:xml(['a', map { 'x': map { 'foo': map { 'y': 10 }}}]),
        <a>
            <x>
                <foo y="10"/>
            </x>
        </a>,
        "A map attribute value can be nested."
    ),

    unit:assert-equals(
        o:xml(['a', map { 'x': sum#1 }]),
        <a x="sum#1"/>,
        "A function value results uses name and arity as attribute value."
    )
};

declare %unit:test function test:namespaces()
{
    unit:assert-equals(
        o:xml(['a'], map { '': 'foobar' }),
        <a xmlns="foobar"/>,
        "A map as second argument will be used as a namespace map"
    ),
    
    unit:assert-equals(
        o:xml(['b:a'], map { 'b': 'foobar' }),
        <b:a xmlns:b="foobar"/>,
        "A map as second argument will be used as a namespace map (2)"
    ),
    
    unit:assert-equals(
        o:xml(['a', map { 'b:x': 10 }], map { 'b': 'foobar' }),
        <a xmlns:b="foobar" b:x="10"/>,
        "Attributes with namespace prefix"
    ),

    unit:assert-equals(
        o:xml(['a', map { 'c': 20 }], map { '': 'bla' }),
        <a xmlns="bla" c="20"/>,
        "Attributes should not take default prefix"
    ),

    unit:assert-equals(
        o:xml(['a', map { 'b:x': 10, 'c': 20 }], map { '': 'bla', 'b': 'foobar' }),
        <a xmlns="bla" xmlns:b="foobar" b:x="10" c="20"/>,
        "Attributes with namespace prefix and a default namespace"
    )

};

declare %unit:test("expected", "Q{http://xokomola.com/xquery/origami}unwellformed")
function test:unwellformed()
{
    unit:assert-equals(
        o:xml([map {'x': 1}, 'a', ('b', 'c')]),
        <a x="1">bc</a>
    )
};

declare %unit:test function test:xml-node-sequence()
{
    (:
     : Return a sequence of elements.
     :)
    unit:assert-equals(
        o:xml((['a'],['b'])),
        (<a/>,<b/>)
    ),
    
    unit:assert-equals(
        o:xml(('a','b')),
        (text { 'a' }, text { 'b' })
    )   
};

declare %unit:test function test:xml-nodes-mixed()
{
    unit:assert-equals(
        <a>{ o:xml(['b']) }</a>,
        <a><b/></a>
    ),
    
    unit:assert-equals(
        o:xml(['a', <b/>]),
        <a><b/></a>
    ),
    
    (: bare mu-nodes inside xml-nodes will be atomized. :)
    unit:assert-equals(
        o:xml(['a', <b>{ ['c', ['d']] }</b>]),
        <a><b>c d</b></a>
    )
};

declare %unit:test function test:parse-xml() 
{
    unit:assert-equals(
        o:doc(<x/>),
        ['x']),

    unit:assert-equals(
        o:doc((<x/>, <y/>)),
        (['x'], ['y'])),

    unit:assert-equals(
        o:doc(<x>hello</x>),
        ['x', 'hello']),

    unit:assert-equals(
        o:doc(<x><y/></x>),
        ['x', ['y']]),

    unit:assert-equals(
        o:doc(<x a="10" b="y"/>),
        ['x', map { 'a': '10', 'b': 'y' }]),

    unit:assert-equals(
        o:doc(<x a="10" b="y">hello</x>),
        ['x', map { 'a': '10', 'b': 'y' }, 'hello']),

    unit:assert-equals(
        o:doc(<x a="10" b="y">hello <b>world</b></x>),
        ['x', map { 'a': '10', 'b': 'y' }, 'hello ', ['b', 'world']]),

    unit:assert-equals(
        o:doc(<x><!-- hello -->world</x>),
        ['x', 'world'],
        "Comment nodes will be removed"
    ),

    unit:assert-equals(
        o:doc(<x><?foo hello ?>world</x>),
        ['x', 'world'],
        "Processing instruction nodes will be removed"
    )
};

declare %unit:test function test:cdata()
{
    (: this works :)
    unit:assert-equals(
        o:xml(['b',<c><![CDATA[>]]></c>]),
        <b><c>&gt;</c></b>
    )
    
    (: but this doesn't :)
    (:
    unit:assert-equals(
        o:xml(['b',<c><![CDATA[{'x'}]]></c>]),
        <b><c>x</c></b>
    ),    
    unit:assert-equals(
        o:xml(['b',<![CDATA[>]]>]),
        <b><c>x</c></b>
    ) 
    :)
};
