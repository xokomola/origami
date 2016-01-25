xquery version "3.1";

(:~
 : Tests for μ-templates
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami'
    at '../origami.xqm'; 

declare namespace h = 'http://www.w3.org/1999/xhtml';

declare %unit:test function test:xml() 
{
  (:
    (:~
     : A string becomes a text node.
     :)
    unit:assert-equals(
        o:xml('a'),
        text { 'a' }
    ),
    
    unit:assert-equals(
        o:xml(('a','b','c')),
        (text { 'a' }, text { 'b'}, text { 'c' })
    ),
    
    (:~
     : A one item array creates an empty element without attributes.
     :)
    unit:assert-equals(
        o:xml(['a']),
        <a/>
    ),

    (:~
     : A two item array creates an element with child nodes.
     :)
    unit:assert-equals(
        o:xml(['a','hello']),
        <a>hello</a>
    ),
    
    unit:assert-equals(
        o:xml(['a','hello', 'world']),
        <a>helloworld</a>
    ),

    (:~
     : A two item array with the second item being a map returns
     : an empty element with attributes.
     :)
    unit:assert-equals(
        o:xml(['a',map { 'x': 10, 'b': 'y' }]),
        <a x="10" b="y"/>
    ),
    
    (:~
     : Or, without attributes if the map is empty.
     :)
    unit:assert-equals(
        o:xml(['a',map { }]),
        <a/>
    ),
    
    (:~
     : A three item array returns an element with attributes
     : and child nodes.
     :)
    unit:assert-equals(
        o:xml(['a',map { 'x': 10, 'b': 'y' }, 'hello']),
        <a x="10" b="y">hello</a>
    ),

    (:~
     : Or without attributes.
     :)
    unit:assert-equals(
        o:xml(['a',map { }, 'hello']),
        <a>hello</a>
    ),
:)
    (:~
     : Or without child nodes.
     :)
    unit:assert-equals(
        o:xml(['a',map { 'x': 10, 'b': 'y' }, ()]),
        <a x="10" b="y"/>
    ),

    (:~
     : Or an empty element.
     :)
    unit:assert-equals(
        o:xml(['a', map { }, ()]),
        <a/>
    ),
   
    (:~
     : If an item is already an XML node than it is passed
     : unmodified.
     :)
    unit:assert-equals(
        o:xml(<a/>),
        <a/>
    ),

    (:~
     : Element items may be nested.
     :)
    unit:assert-equals(
        o:xml(['a', (['b'], ['c'])]),
        <a>
            <b/>
            <c/>
        </a>
    ),

    unit:assert-equals(
        o:xml(['a', ['b', ['c']]]),
        <a>
            <b>
                <c/>
            </b>
        </a>
    ),

    unit:assert-equals(
        o:xml(['a', ('b','c')]),
        <a>bc</a>
    ),

    unit:assert-equals(
        o:xml(['a', ('b','c')]),
        <a>{ text { 'b' }, text { 'c' }}</a>
    ),

    unit:assert-equals(
        o:xml(['a', 'b', 'c']),
        <a>bc</a>
    ),

    (:~
     : Atomic values will be converted into text nodes.
     :)
    unit:assert-equals(
        o:xml(['a', (10,'c')]),
        <a>10c</a>
    ),
   
    (:~
     : Mixed content.
     :)
    unit:assert-equals(
        o:xml(['a', ('foo', ['b', 'bar', ['c'], 'baz'])]),
        <a>foo<b>bar<c/>baz</b></a>
    ),
  
    (:~
     : Sequence as content.
     :)
    unit:assert-equals(
        o:xml(['a', (map {'x': 10}, 'foo')]),
        <a x="10">foo</a>,
        "The attributes map may be part of the child content"
    ),
    
    (:~
     : Sequence as content.
     :)
    unit:assert-equals(
        o:xml([('a', map {'x': 10}, 'foo')]),
        <a x="10">foo</a>,
        "The whole element may be wrapped in a sequence."
    ),

    (:~
     : Complex attribute values.
     :
     : TODO: review this.
     :)
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
    
    (: bare μ-nodes inside xml-nodes will be atomized. :)
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
        ['x', 'world'])
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
