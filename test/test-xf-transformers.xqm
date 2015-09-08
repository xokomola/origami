xquery version "3.1";

(:~
 : Origami tests: node transformers
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu' 
    at '../mu.xqm'; 

(: 
 : NOTE: functions cannot be compared so although they 
 :       may appear as part of mu nodes.
 :)
declare %unit:test %unit:ignore function test:content()
{
    unit:assert-equals(
        ['p'] => μ:content(['x']),
        ['p', ['x']]
    ),    
    unit:assert-equals(
        ['p', 'foo'] => μ:content(['x']),
        ['p', ['x']]
    ),
    unit:assert-equals(
        ['p', map { 'a': 1 }, 'foo'] => μ:content(['x']),
        ['p', map { 'a': 1 },['x']]
    )        
};

declare %unit:test %unit:ignore function test:replace()
{
    unit:assert-equals(
        ['p'] => μ:replace(['x']),
        ['x']
    ),    
    unit:assert-equals(
        ['p', 'foo'] => μ:replace(['x']),
        ['x']
    ),
    unit:assert-equals(
        ['p', map { 'a': 1 }, 'foo'] => μ:replace(['x']),
        ['x']
    )        
};

declare %unit:test %unit:ignore function test:wrap()
{
    unit:assert-equals(
        ['p'] => μ:wrap(['x']),
        ['x', ['p']]
    ),    
    unit:assert-equals(
        ['p'] => μ:wrap(['x', map { 'a': 1 }]),
        ['x', map { 'a': 1 }, ['p']]
    ),
    unit:assert-equals(
        ['p'] => μ:wrap(['x', map { 'a': 1 }, 'foo']),
        ['x', map { 'a': 1 }, ['p']]
    ),        
    unit:assert-equals(
        ['p'] => μ:wrap(['x', 'foo']),
        ['x', ['p']]
    )
};