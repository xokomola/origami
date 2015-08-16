xquery version "3.1";

(:~
 : Origami tests: node transformers
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace λ = 'http://xokomola.com/xquery/origami/xf'
    at '../xf.xqm';

(: 
 : NOTE: functions cannot be compared so although they 
 :       may appear as part of mu nodes.
 :)
declare %unit:test %unit:ignore function test:content()
{
    unit:assert-equals(
        ['p'] => λ:content(['x']),
        ['p', ['x']]
    ),    
    unit:assert-equals(
        ['p', 'foo'] => λ:content(['x']),
        ['p', ['x']]
    ),
    unit:assert-equals(
        ['p', map { 'a': 1 }, 'foo'] => λ:content(['x']),
        ['p', map { 'a': 1 },['x']]
    )        
};

declare %unit:test %unit:ignore function test:replace()
{
    unit:assert-equals(
        ['p'] => λ:replace(['x']),
        ['x']
    ),    
    unit:assert-equals(
        ['p', 'foo'] => λ:replace(['x']),
        ['x']
    ),
    unit:assert-equals(
        ['p', map { 'a': 1 }, 'foo'] => λ:replace(['x']),
        ['x']
    )        
};

declare %unit:test %unit:ignore function test:wrap()
{
    unit:assert-equals(
        ['p'] => λ:wrap(['x']),
        ['x', ['p']]
    ),    
    unit:assert-equals(
        ['p'] => λ:wrap(['x', map { 'a': 1 }]),
        ['x', map { 'a': 1 }, ['p']]
    ),
    unit:assert-equals(
        ['p'] => λ:wrap(['x', map { 'a': 1 }, 'foo']),
        ['x', map { 'a': 1 }, ['p']]
    ),        
    unit:assert-equals(
        ['p'] => λ:wrap(['x', 'foo']),
        ['x', ['p']]
    )
};