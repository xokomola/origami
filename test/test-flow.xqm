xquery version "3.1";

(:~
 : Test for various functional utilities (for-each, filter, seq, conj, comp)
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami.xqm'; 

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
        "z-y-x-a"
    )
};

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

declare %unit:test function test:for-each-is-like-flatmap()
{
    unit:assert-equals(
        (['x'], ['x']) 
        => o:for-each(function($n) { (['y'], ['y']) }),
        (['y'],['y'],['y'],['y'])
    )
};

declare %unit:test function test:filter-on-element()
{
    unit:assert-equals(
        ['p', ['p', ['x', ['y']]], ['x']] 
            => o:for-each(function($n) { 
                if (o:tag($n) = 'x') 
                then $n 
                else () 
            }),
        () 
    ),

    unit:assert-equals(
        () => o:for-each(function($n) { 
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
            => o:for-each(function($n) { 
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

declare %unit:test function test:tree-seq()
{
    unit:assert-equals(
        o:tree-seq(()),
        ()
    ),

    unit:assert-equals(
        o:tree-seq((), o:is-element#1, o:identity#1),
        ()
    ),

    unit:assert-equals(
        o:tree-seq((['a'],['b'],['c'])),
        (['a'],['b'],['c'])
    ),
    
    unit:assert-equals(
        o:tree-seq((['a'],['b'],['c']), o:is-element#1, o:identity#1),
        (['a'],['b'],['c'])
    ),
    
    unit:assert-equals(
        o:tree-seq((['a', 'b', ['c']])),
        (['a', 'b', ['c']], 'b', ['c'])
    ),
    
    unit:assert-equals(
        o:tree-seq(['a', 'b',['c']], o:is-element#1, o:identity#1),
        (['a', 'b', ['c']], 'b', ['c'])
    ),
    
    unit:assert-equals(
        o:tree-seq((['a', map { 'x': 10 },['c']])),
        (['a', map { 'x': 10 }, ['c']],['c'])
    ),
    
    unit:assert-equals(
        o:tree-seq(['a', map { 'x': 10 },['c']], o:is-element#1, o:identity#1),
        (['a', map { 'x': 10 }, ['c']],['c'])
    ),

    unit:assert-equals(
        o:tree-seq(['a', ['b', ['c', ['d']]]]),
        (['a', ['b', ['c', ['d']]]], ['b', ['c', ['d']]], ['c', ['d']], ['d'])
    ),
    
    unit:assert-equals(
        o:tree-seq(['a', ['b', ['c', ['d']]]], o:is-element#1, o:identity#1),
        (['a', ['b', ['c', ['d']]]], ['b', ['c', ['d']]], ['c', ['d']], ['d'])
    )
};

declare %unit:test function test:tree-seq-transform()
{
    unit:assert-equals(
        o:tree-seq(['a',['b']], function($n) { 'element' }),
        ('element','element'),
        "Replace each element by a string"
    ),

    unit:assert-equals(
        o:tree-seq(['a',['b']], function($n) { ($n,$n) }),
        (['a',['b']],['a',['b']],['b'],['b']),
        "Double each node"
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

declare %unit:test function test:walk-identity()
{
    unit:assert-equals(
        o:postwalk([1,2,[3,4,[5,6]]], o:identity#1),
        [1,2,[3,4,[5,6]]],
        "Post-order traversal"
    ),
    
    unit:assert-equals(
        o:prewalk([1,2,[3,4,[5,6]]], o:identity#1),
        [1,2,[3,4,[5,6]]],
        "Pre-order traversal"
    )
};

declare %unit:test function test:walk-sum()
{
    unit:assert-equals(
        o:postwalk( 
            [1,2,[3,4,[5,6]]],
            function($n) { 
                sum($n?*) 
            }
        ),
        21
    )
};

declare %unit:test function test:walk-inc-head()
{
    unit:assert-equals(
        o:prewalk(
            [1,2,[3,4,[5,6]]],
            function($n) { 
                [array:head($n)+10, array:tail($n)?*]
            } 
        ),
        [11,2,[13,4,[15,6]]]
    )
};

declare %unit:test function test:walk-to-text()
{
    unit:assert-equals(
        o:postwalk(
            ['1','2',['3','4',['5','6']]],
            function($n) { 
              concat('[',string-join($n?*, '-'),']')
            } 
        ),
        '[1-2-[3-4-[5-6]]]'
    )
};

declare %unit:test function test:walk-uppercase-elements()
{
    unit:assert-equals(
        o:postwalk(
            ['foo', map { 'x': 10 }, ['bar', ['baz', 'hello']]],
            function($n) { 
                array { upper-case(o:head($n)), o:tail($n) }
            }
        ),
        ['FOO', map { 'x': 10 }, ['BAR', ['BAZ', 'hello']]]
    ),
    
    unit:assert-equals(
        o:prewalk(
            ['foo', map { 'x': 10 }, ['bar', ['baz', 'hello']]],
            function($n) { 
                array { upper-case(o:head($n)), o:tail($n) }
            }
        ),
        ['FOO', map { 'x': 10 }, ['BAR', ['BAZ', 'hello']]]
    )
};
