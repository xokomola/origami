xquery version "3.1";

(:~
 : Tests for μ-templates
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/μ' at '../mu.xqm'; 

declare namespace h = 'http://www.w3.org/1999/xhtml';

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
