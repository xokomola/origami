xquery version "3.1";

(:~
 : Origami tests: node map/select
 :)
 
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami.xqm'; 

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
            => o:select(function($n) { o:tag($n) = 'x' }),
        () 
    ),        

    unit:assert-equals(
        () => o:select(function($n) { o:tag($n) = 'x' }),
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
            => o:select(function($n) { o:attrs($n)?class = 'x' }),
        () 
    )        
};

declare %unit:test function test:seq()
{
    unit:assert-equals(
        o:seq((1,2,3)),
        (1,2,3)
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