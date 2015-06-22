xquery version "3.1";

(:~
 : Tests for μ-templates
 :)
module namespace test = 'http://xokomola.com/xquery/origami/μ/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/μ' at '../mu.xqm'; 

declare namespace h = 'http://www.w3.org/1999/xhtml';

declare %unit:test function test:xml() 
{
    (:~
     : A string becomes a text node.
     :)
    unit:assert-equals(
        μ:xml('a'),
        text { 'a' }
    ),

    unit:assert-equals(
        μ:xml(('a','b','c')),
        (text { 'a' }, text { 'b'}, text { 'c' })
    ),
    
    (:~
     : A one item array creates an empty element without attributes.
     :)
    unit:assert-equals(
        μ:xml(['a']),
        <a/>
    ),

    (:~
     : A two item array creates an element with child nodes.
     :)
    unit:assert-equals(
        μ:xml(['a','hello']),
        <a>hello</a>
    ),
    
    unit:assert-equals(
        μ:xml(['a','hello', 'world']),
        <a>helloworld</a>
    ),

    (:~
     : A two item array with the second item being a map returns
     : an empty element with attributes.
     :)
    unit:assert-equals(
        μ:xml(['a',map { 'x': 10, 'b': 'y' }]),
        <a x="10" b="y"/>
    ),

    (:~
     : Or, without attributes if the map is empty.
     :)
    unit:assert-equals(
        μ:xml(['a',map { }]),
        <a/>
    ),
    
    (:~
     : A three item array returns an element with attributes
     : and child nodes.
     :)
    unit:assert-equals(
        μ:xml(['a',map { 'x': 10, 'b': 'y' }, 'hello']),
        <a x="10" b="y">hello</a>
    ),

    (:~
     : Or without attributes.
     :)
    unit:assert-equals(
        μ:xml(['a',map { }, 'hello']),
        <a>hello</a>
    ),

    (:~
     : Or without child nodes.
     :)
    unit:assert-equals(
        μ:xml(['a',map { 'x': 10, 'b': 'y' }, ()]),
        <a x="10" b="y"/>
    ),

    (:~
     : Or an empty element.
     :)
    unit:assert-equals(
        μ:xml(['a', map { }, ()]),
        <a/>
    ),
    
    (:~
     : If an item is already an XML node than it is passed
     : unmodified.
     :)
    unit:assert-equals(
        μ:xml(<a/>),
        <a/>
    ),

    (:~
     : Element items may be nested.
     :)
    unit:assert-equals(
        μ:xml(['a', (['b'], ['c'])]),
        <a>
            <b/>
            <c/>
        </a>
    ),

    unit:assert-equals(
        μ:xml(['a', ['b', ['c']]]),
        <a>
            <b>
                <c/>
            </b>
        </a>
    ),

    unit:assert-equals(
        μ:xml(['a', ('b','c')]),
        <a>bc</a>
    ),

    unit:assert-equals(
        μ:xml(['a', ('b','c')]),
        <a>{ text { 'b' }, text { 'c' }}</a>
    ),

    unit:assert-equals(
        μ:xml(['a', 'b', 'c']),
        <a>bc</a>
    ),

    unit:assert-equals(
        μ:xml(['a', (map {'x': 1}, (map {'y': 2 }, 'b', 'c'))]),
        <a x="1" y="2">bc</a>
    ),

    (: with naughty attribute/map values :)
    unit:assert-equals(
        μ:xml(['a', (map {'x': 1}, (map {'y': (2,3) }, 'b', 'c'))]),
        <a x="1" y="2 3">bc</a>
    ),

    (:~
     : Atomic values will be converted into text nodes.
     :)
    unit:assert-equals(
        μ:xml(['a', (10,'c')]),
        <a>10c</a>
    ),
    
    (:~
     : Mixed content.
     :)
    unit:assert-equals(
        μ:xml(['a', ('foo', ['b', 'bar', ['c'], 'baz'])]),
        <a>foo<b>bar<c/>baz</b></a>
    )  
};

declare %unit:test function test:xml-node-sequence()
{
    (:
     : Return a sequence of elements.
     :)
    unit:assert-equals(
        μ:xml((['a'],['b'])),
        (<a/>,<b/>)
    ),
    
    unit:assert-equals(
        μ:xml(('a','b')),
        (text { 'a' }, text { 'b' })
    )   
};

declare %unit:test function test:xml-nodes-mixed()
{
    unit:assert-equals(
        <a>{ μ:xml(['b']) }</a>,
        <a><b/></a>
    ),
    
    unit:assert-equals(
        μ:xml(['a', <b/>]),
        <a><b/></a>
    ),
    
    (: bare μ-nodes inside xml-nodes will be atomized. :)
    unit:assert-equals(
        μ:xml(['a', <b>{ ['c', ['d']] }</b>]),
        <a><b>c d</b></a>
    )
};

(:
 : So far I have not encountered examples that could not
 : be round-tripped with μ:xml and result in the same
 : XML nodes.
 :)
declare %unit:test function test:json()
{
    unit:assert-equals(
        parse-json(μ:json('a')),
        'a'
    ),

    (:
     : Multiple top-level items cannot be serialized into JSON
     : therefore multiple top-level items are wrapped in an array.
     :)
    unit:assert-equals(
        parse-json(μ:json(('a','b','c'))),
        ['a','b','c']
    ),

    unit:assert-equals(
        parse-json(μ:json(['a'])),
        ['a']
    ),

    unit:assert-equals(
        parse-json(μ:json(['a', 'hello'])),
        ['a', 'hello']
    ),

    unit:assert-equals(
        parse-json(μ:json(['a', 'hello', 'world'])),
        ['a', 'hello', 'world']
    ),

    unit:assert-equals(
        parse-json(μ:json(['a', map { 'x': 10, 'b': 'y' }])),
        ['a', map { 'x': 10, 'b': 'y' }]
    ),

    unit:assert-equals(
        parse-json(μ:json(['a', map { }])),
        ['a', map { }]
    ),

    unit:assert-equals(
        parse-json(μ:json(['a', map { 'x': 10, 'b': 'y' }, 'hello'])),
        ['a', map { 'x': 10, 'b': 'y' }, 'hello']
    ),

    (: 
     : sequences are not kept in JSON but this is not an issue as they
     : do not generate a different structure.
     :)
    unit:assert-equals(
        parse-json(μ:json((['a'],['b']))),
        [['a'],['b']]
    ),

    unit:assert-equals(
        parse-json(μ:json(['a', (['b'], ['c'])])),
        ['a', ['b'], ['c']]
    ),
    
    (: embedded empty sequences are represented as "null" in JSON. :)
    unit:assert-equals(
        parse-json(μ:json(['a', map { }, ()])),
        ['a', map { }, ()]
    ),

    unit:assert-equals(
        parse-json(μ:json(['a', ['b']])),
        ['a', ['b']]
    ),

    unit:assert-equals(
        parse-json(μ:json(['a', (map {'x': 1}, (map {'y': 2 }, 'b', 'c'))])),
        ['a', map {'x': 1}, map {'y': 2 }, 'b', 'c']
    ),

    unit:assert-equals(
        parse-json(μ:json(['a', (map {'x': 1}, (map {'y': [2,3] }, 'b', 'c'))])),
        ['a', map {'x': 1}, map {'y': [2,3] }, 'b', 'c']
    ),

    (: TODO: need to wrap essential sequences in array :)
    (:
    unit:assert-equals(
        parse-json(μ:json(['a', (map {'x': 1}, (map {'y': (2,3) }, 'b', 'c'))])),
        ['a', map {'x': 1}, map {'y': [2,3] }, 'b', 'c']
    ),
    :)

    unit:assert-equals(
        parse-json(μ:json(['a', ('foo', ['b', 'bar', ['c'], 'baz'])])),
        ['a', 'foo', ['b', 'bar', ['c'], 'baz']]
    ),

    unit:assert-equals(
        parse-json(μ:json(['a', (10,'c')])),
        ['a', 10, 'c']
    ),

    (: this will produce a sequence of attributes when serialized to XML :)   
    unit:assert-equals(
        parse-json(μ:json(map { 'x': 1, 'y': 2 })),
        map { 'x': 1, 'y': 2 }
    ),

    (: but this is illegal in XML and results in "Items of type map(*) cannot be atomized." :)
    unit:assert-equals(
        parse-json(μ:json([map { 'x': 1, 'y': 2 }])),
        [map { 'x': 1, 'y': 2 }]
    ),

    unit:assert-equals(
        parse-json(μ:json(['a', map { 'x': 1 }, 'foo'])),
        ['a', map { 'x': 1 }, 'foo']
    ),

    unit:assert-equals(
        parse-json(μ:json(['a', map { 'x': 1 }, 'foo', 'bar'])),
        ['a', map { 'x': 1 }, 'foo', 'bar']
    ),
    
    unit:assert-equals(
        parse-json(μ:json(['a', map { 'x': 1 }, 'foo', ['b', 'bar'], 'baz'])),
        ['a', map { 'x': 1 }, 'foo', ['b', 'bar'], 'baz']
    ),
    
    unit:assert-equals(
        parse-json(μ:json(['a', map { 'x': 1 }, ('foo', ['b', 'bar'], 'baz')])),
        ['a', map { 'x': 1 }, 'foo', ['b', 'bar'], 'baz']
    ),

    unit:assert-equals(
        parse-json(μ:json(['a', map { 'x': 1 }, ('foo', (['b', 'bar'], 'baz'))])),
        ['a', map { 'x': 1 }, 'foo', ['b', 'bar'], 'baz']
    ),
    
    (: nodes will be converted to μ-nodes before serializing to JSON :)
    unit:assert-equals(
        parse-json(μ:json(['a', <b/>])),
        ['a', ['b']]
    ),

    (: attribute nodes become string map entry values :)
    unit:assert-equals(
        parse-json(μ:json(['a', <b><c y="1">foo</c></b>, '!'])),
        ['a', ['b', ['c', map { 'y': '1' }, 'foo']], '!']
    ),

    unit:assert-equals(
        parse-json(μ:json(μ:xml(['a', <b/>]))),
        ['a', ['b']]
    ),

    unit:assert-equals(
        parse-json(μ:json(<a>{ μ:xml(['b']) }</a>)),
        ['a', ['b']]
    ),

    (: bare μ-nodes inside xml-nodes will be atomized. :)
    unit:assert-equals(
        parse-json(μ:json(μ:xml(['a', <b>{ ['c', ['d']] }</b>]))),
        ['a', ['b', 'c d']]
    )

};

declare %unit:test function test:xml-template()
{
    (:~
     : This is the simplest way to build a list.
     :)
    unit:assert-equals(
        μ:xml(['ul', 
                for $i in 1 to 3
                return ['li', concat('item ', $i)] ]),
        <ul><li>item 1</li><li>item 2</li><li>item 3</li></ul>
    ),

    (: μ:xml-template returns a function with arity one :)
    unit:assert-equals(
        μ:xml-template(['ul', 
            function($x) { 
                for $i in 1 to $x 
                return ['li', concat('item ', $i)] 
            }])(3),
        <ul><li>item 1</li><li>item 2</li><li>item 3</li></ul>
    ),
   
    (:~
     : The function may produce XML nodes. This is identical
     : to the above but uses a literal element constructor
     : to construct the li elements.
     :)
    unit:assert-equals(
        μ:xml-template(['ul', 
            function($x) { 
                for $i in 1 to $x 
                return element li { concat('item ', $i) } 
            }
        ])(3),
        <ul>
            <li>item 1</li>
            <li>item 2</li>
            <li>item 3</li>
        </ul>
    ),
  
    (:~
     : Produce a table. Multiple arguments have to be specified as a sequence
     : or an array (the outer sequence will be changed into an array so it
     : can be used with fn:apply.
     :)
    unit:assert-equals(
        μ:xml-template(['table', 
            function($r,$c) { 
                for $i in 1 to $r 
                return 
                    ['tr', 
                        function($r,$c) {
                            for $j in 1 to $c
                            return
                                ['td', concat('item ',$i,',',$j)]
                        }]
            }
        ])([3,2]),
        <table>
            <tr>
              <td>item 1,1</td>
              <td>item 1,2</td>
            </tr>
            <tr>
              <td>item 2,1</td>
              <td>item 2,2</td>
            </tr>
            <tr>
              <td>item 3,1</td>
              <td>item 3,2</td>
            </tr>
          </table>
    )
};

declare %unit:test function test:xml-templates-obfuscated()
{
    (: Not very useful but xml-templates can be nested. :)
    unit:assert-equals(
        μ:xml-template(['ul', 
            function($x) { 
                for $i in 1 to $x 
                return μ:xml-template(function($x) { ['li', concat('item ', $x)] })($i) 
            }])(3),
        <ul><li>item 1</li><li>item 2</li><li>item 3</li></ul>
    ),

    (: Still not very useful, but demonstrates how the above is simplified a bit :)
    unit:assert-equals(
        μ:xml-template(['ul', 
            function($x) { 
                for $i in 1 to $x 
                return function($x) { ['li', concat('item ', $x)] }($i) 
            }])(3),
        <ul><li>item 1</li><li>item 2</li><li>item 3</li></ul>
    )
};

declare %unit:test("expected", "err:FOAP0001") function test:xml-template-arity-error()
{
    (: 
     : When a template receives the incorrect number of arguments it will raise an
     : arity error.
     :)
    unit:assert-equals(
        μ:xml-template(['table', 
            function($r,$c) { 
                for $i in 1 to $r 
                return 
                    ['tr', 
                        function($r,$c) {
                            for $j in 1 to $c
                            return
                                ['td', concat('item ',$i,',',$j)]
                        }]
            }
        ])((3,2,1)),
        <table>
            <tr>
              <td>item 1,1</td>
              <td>item 1,2</td>
            </tr>
            <tr>
              <td>item 2,1</td>
              <td>item 2,2</td>
            </tr>
            <tr>
              <td>item 3,1</td>
              <td>item 3,2</td>
            </tr>
          </table>
    )
};

declare %unit:test function test:mu() 
{
    unit:assert-equals(
        μ:mu(<x/>),
        ['x']),

    unit:assert-equals(
        μ:mu((<x/>, <y/>)),
        (['x'], ['y'])),

    unit:assert-equals(
        μ:mu(<x>hello</x>),
        ['x', 'hello']),

    unit:assert-equals(
        μ:mu(<x><y/></x>),
        ['x', ['y']]),

    unit:assert-equals(
        μ:mu(<x a="10" b="y"/>),
        ['x', map { 'a': '10', 'b': 'y' }]),

    unit:assert-equals(
        μ:mu(<x a="10" b="y">hello</x>),
        ['x', map { 'a': '10', 'b': 'y' }, 'hello']),

    unit:assert-equals(
        μ:mu(<x a="10" b="y">hello <b>world</b></x>),
        ['x', map { 'a': '10', 'b': 'y' }, 'hello ', ['b', 'world']]),

    unit:assert-equals(
        μ:mu(<x><!-- hello -->world</x>),
        ['x', 'world'])
};

declare %unit:test function test:cdata()
{
    (: this works :)
    unit:assert-equals(
        μ:xml(['b',<c><![CDATA[>]]></c>]),
        <b><c>&gt;</c></b>
    )
    
    (: but this doesn't :)
    (:
    unit:assert-equals(
        μ:xml(['b',<c><![CDATA[{'x'}]]></c>]),
        <b><c>x</c></b>
    ),    
    unit:assert-equals(
        μ:xml(['b',<![CDATA[>]]>]),
        <b><c>x</c></b>
    ) 
    :)
};

declare %unit:test function test:xhtml()
{    
    (:~
     : EXPERIMENTAL:
     : This only works for namespaces that are also declared inside
     : the library module. It cannot be changed unilaterally by the user.
     :)
    unit:assert-equals(
        μ:xml(['h:html']),
        <h:html/>
    ),
    
    unit:assert-equals(
        μ:xml(['h:html', ['x']]),
        <h:html><x/></h:html>
    ),

    unit:assert-equals(
        μ:mu(<h:html><x/></h:html>),
        ['h:html', ['x']]
    )
};
