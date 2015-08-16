xquery version "3.1";

(:~
 : Tests for μ-templates
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu' at '../mu.xqm'; 

declare %unit:test function test:apply-attributes() 
{
        unit:assert-equals(
            μ:apply(['x', map { 'a': function($x,$y) { $x + $y }}], [2,4]),
            ['x', map { 'a': 6 }]
        )
};


