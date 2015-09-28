xquery version "3.1";

(:~
 : Origami tests: node transformers
 :)
 
(: TODO: mix with xml nodes :)
(: TODO: node sequences :)

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
        (
            ['x', ['y']], 
            ['x']
        ) 
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
        (
            ['x', ['y']], 
            ['x']
        ) 
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
        (
            ['p', map { 'class': 'x' }, ['x', ['y', map { 'class': 'x' }]]], 
            ['y', map { 'class': 'x' }]
        ) 
    ),
            
    unit:assert-equals(
        ['p', ['p', map { 'class': 'x' }, ['x', ['y', map { 'class': 'x' }]]], ['x']] 
            => o:filter(function($n) { o:attrs($n)?class = 'x' }),
        (
            ['p', map { 'class': 'x' }, ['x', ['y', map { 'class': 'x' }]]], 
            ['y', map { 'class': 'x' }]
        ) 
    )        
};

