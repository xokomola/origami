xquery version "3.1";

(:~
 : Tests for walkers.
 :)

module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami'
    at '../origami.xqm'; 

declare %unit:test function test:walk-identity()
{
    unit:assert-equals(
        o:postwalk(o:identity#1, [1,2,[3,4,[5,6]]]),
        [1,2,[3,4,[5,6]]],
        "Post-order traversal"
    ),
    
    unit:assert-equals(
        o:prewalk(o:identity#1, [1,2,[3,4,[5,6]]]),
        [1,2,[3,4,[5,6]]],
        "Pre-order traversal"
    )
};

declare %unit:test function test:walk-sum()
{
    unit:assert-equals(
        o:postwalk(
            function($n) { 
                sum($n?*) 
            }, 
            [1,2,[3,4,[5,6]]]
        ),
        21
    )
};

declare %unit:test function test:walk-inc-head()
{
    unit:assert-equals(
        o:prewalk(
            function($n) { 
                [array:head($n)+10, array:tail($n)?*]
            }, 
            [1,2,[3,4,[5,6]]]
        ),
        [11,2,[13,4,[15,6]]]
    )
};

declare %unit:test function test:walk-uppercase-elements()
{
    unit:assert-equals(
        o:postwalk(
            function($n) { 
                array { upper-case(o:head($n)), o:tail($n) }
            }, 
            ['foo', map { 'x': 10 }, ['bar', ['baz', 'hello']]]
        ),
        ['FOO', map { 'x': 10 }, ['BAR', ['BAZ', 'hello']]]
    ),
    
    unit:assert-equals(
        o:prewalk(
            function($n) { 
                array { upper-case(o:head($n)), o:tail($n) }
            }, 
            ['foo', map { 'x': 10 }, ['bar', ['baz', 'hello']]]
        ),
        ['FOO', map { 'x': 10 }, ['BAR', ['BAZ', 'hello']]]
    )
};