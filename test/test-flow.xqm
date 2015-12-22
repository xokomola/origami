xquery version "3.1";

(:~
 : Tests for flow control node transformers.
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami.xqm'; 

declare %unit:test function test:repeat()
{
    unit:assert-equals(
        o:repeat(1 to 5)(1),
        (1,1,1,1,1)
    ),
    
    unit:assert-equals(
        o:repeat(1 to 5)((1,2)),
        (1,2,1,2,1,2,1,2,1,2)
    ),

    unit:assert-equals(
        o:repeat(1 to 5)(['a']),
        (['a'],['a'],['a'],['a'],['a'])
    )
};

declare %unit:test function test:sort()
{
    unit:assert-equals(
        o:sort()((2,1,3)),
        (1,2,3)
    ),
    
    unit:assert-equals(
        o:sort(data#1)((2,1,3)),
        (1,2,3)
    ),

    unit:assert-equals(
        o:sort((2,1,3),data#1),
        (1,2,3)
    ),
    
    unit:assert-equals(
        o:sort(('b','a','c'),data#1),
        ('a','b','c')
    ),
    
    unit:assert-equals(
        o:sort(('b',2,'a',1,'c',3),xs:string#1),
        (1,2,3,'a','b','c')
    )

};

declare %unit:test function test:choose() 
{
    unit:assert-equals(
        o:choose(['x'],1,['a','b','c']),
        'a',
        "Choose from array"
    ),
    
    unit:assert-equals(
        o:choose(['x'],(1,3),['a','b','c']),
        ('a','c'),
        "Choose from array (multiple)"
    ),
    
    unit:assert-equals(
        o:choose(['x'],'a',map { 'a': 10, 'b': 20, 'c': 30 }),
        10,
        "Choose from map"
    ),   

    unit:assert-equals(
        o:choose(['x'],('a','c'),map { 'a': 10, 'b': 20, 'c': 30 }),
        (10,30),
        "Choose from map (multiple)"
    ),

    unit:assert-equals(
        o:choose(['x'], function($n) { 'a','c' }, map { 'a': 10, 'b': 20, 'c': 30 }),
        (10,30),
        "Choose with function"
    ),

    unit:assert-equals(
        o:choose(['x'], function($n) { 1,3 }, ['a','b','c']),
        ('a','c'),
        "Choose with function"
    ),

    unit:assert-equals(
        o:choose(['x'], function($n) { o:tag($n) }, map { 'x': <x/>, 'y': <y/>}),
        <x/>,
        "Choose with function using input node"
    ),

    unit:assert-equals(
        o:choose(['x'], function($n) { o:tag($n) }, map { 'x': o:insert('foo'), 'y': o:insert('bar') }),
        ['x', 'foo'],
        "Choose with function using input node"
    ),

    unit:assert-equals(
        o:choose(['x'], function($n) { 'x', 'y' }, map { 'x': o:insert('foo'), 'y': o:insert('bar') }),
        (['x', 'foo'],['x', 'bar']),
        "Choose with function selecting node transformers"
    ),

    unit:assert-equals(
        o:choose(['x'], function($n) { 'x', 'y' }, function($x) { 'foobar' }),
        ('foobar','foobar'),
        'Choose with function selecting node transformers'
    ),

    unit:assert-equals(
        o:choose(['x'], function($n) { 1,2 }, function($x) { o:insert($x) }),
        (['x',1],['x',2]),
        'Choose with function returning a function that returns a node transformer'
    )

};
