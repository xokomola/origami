xquery version "3.1";

(:~
 : Test for various functional utilities (map, filter, seq, conj, comp)
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami.xqm'; 

declare %unit:test function test:identity()
{
    unit:assert-equals(
        o:identity(()),
        ()
    ),

    unit:assert-equals(
        o:identity(['x']),
        ['x']
    )
};

declare %unit:test function test:flatten()
{
    unit:assert-equals(
        o:flatten(['a','b','c']),
        ('b','c')
    ),
    
    unit:assert-equals(
        o:flatten(['a',['b','c']]),
        ('c')
    ),

    unit:assert-equals(
        o:flatten()(['a',['b','c','d', ['e','f']]]),
        ('c','d','f')
    )
};

declare %unit:test function test:filter-on-element()
{
    unit:assert-equals(
        ['p', ['p', ['x', ['y']]], ['x']] 
            => o:map(function($n) { 
                if (o:tag($n) = 'x') 
                then $n 
                else () 
            }),
        () 
    ),

    unit:assert-equals(
        () => o:map(function($n) { 
                if (o:tag($n) = 'x') 
                then $n 
                else () 
            }),
        () 
    ),
    
    unit:assert-equals(
        ['p', ['p', ['x', ['y']]], ['x']] 
            => o:filter(function($n) { o:tag($n) = 'x' }),
        () 
    ),        

    unit:assert-equals(
        () => o:filter(function($n) { o:tag($n) = 'x' }),
        () 
    )        

};

declare %unit:test function test:filter-on-attribute()
{
    unit:assert-equals(
        ['p', ['p', map { 'class': 'x' }, ['x', ['y', map { 'class': 'x' }]]], ['x']] 
            => o:map(function($n) { 
                if (o:attrs($n)?class = 'x') 
                then $n 
                else () 
            }),
        () 
    ),
            
    unit:assert-equals(
        ['p', ['p', map { 'class': 'x' }, ['x', ['y', map { 'class': 'x' }]]], ['x']] 
            => o:filter(function($n) { o:attrs($n)?class = 'x' }),
        () 
    )        
};

declare %unit:test function test:seq()
{
    unit:assert-equals(
        o:seq(map { 'a': 10, 'b': 20 }),
        (['a', 10],['b', 20])
    ),
    
    unit:assert-equals(
        o:seq([1,2,3]),
        (1,2,3)
    ),

    unit:assert-equals(
        o:seq([1,(2,3),4]),
        (1,(2,3),4)
    ),
    
    (: but this is true as well :)
    unit:assert-equals(
        o:seq([1,(2,3),4]),
        (1,2,3,4)
    ),
    
    unit:assert-equals(
        o:seq([1,[2,3],4]),
        (1,[2,3],4)
    ),

    unit:assert-equals(
        o:seq([1,[2,3],map{'x': 4}]),
        (1,[2,3],map{'x': 4})
    ),

    unit:assert-equals(
        o:seq([1,<x/>,<y/>]),
        (1,<x/>,<y/>)
    )

};

declare %unit:test function test:conj()
{
    unit:assert-equals(
        o:conj((),'a'),
        ('a')
    ),
    
    unit:assert-equals(
        o:conj(('a'),'b'),
        ('a','b')
    ),

    unit:assert-equals(
        o:conj((),()),
        ()
    ),

    unit:assert-equals(
        o:conj('a',('b','c')),
        ('a','b','c')
    ),

    unit:assert-equals(
        o:conj('a',['b']),
        ('a',['b'])
    ),

    unit:assert-equals(
        o:conj([],'a'),
        ['a']
    ),

    unit:assert-equals(
        o:conj([],('a','b')),
        ['a','b']
    ),

    unit:assert-equals(
        o:conj([],['a','b']),
        [['a','b']]
    )
};

declare %unit:test function test:comp()
{
    unit:assert-equals(
        o:comp((
          o:conj('x'),
          o:conj('y'),
          o:conj('z'),
          reverse#1,
          string-join(?,'-')
        ))('a')
        ,
        "a-x-y-z"
    )
};