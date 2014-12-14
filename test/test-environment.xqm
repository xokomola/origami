xquery version "3.0";

(:~
 : Tests for eval environments.
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare variable $test:matches := xf:xpath-matches(?, xf:expr-environment());
declare variable $test:all-matches := xf:xpath-matches(?, xf:environment());
    
declare %unit:test function test:expr-environment() {
    unit:assert-equals(
        $test:matches('@x')(<foo x="10"/>),
        attribute x { '10' }
    ),
    unit:assert-equals(
        $test:matches('@x')(<foo x="10"><bar x="20"/></foo>),
        attribute x { '10' }
    ),
    unit:assert-equals(
        $test:matches('.')(<foo x="10"><bar x="20"/></foo>),
        <foo x="10"><bar x="20"/></foo>
    ),
    unit:assert-equals(
        $test:matches('/*')(document { <foo x="10"><bar x="20"/></foo> }),
        <foo x="10"><bar x="20"/></foo>
    )
};

declare %unit:test function test:environment() {
    unit:assert-equals(
        $test:all-matches('@x')(<foo x="10"/>),
        attribute x { '10' }
    ),
    unit:assert-equals(
        $test:all-matches('@x')(<foo x="10"><bar x="20"/></foo>),
        (attribute x { '10' }, attribute x { '20' })
    ),
    unit:assert-equals(
        $test:all-matches('.')(<foo x="10"><bar x="20"/></foo>),
        (<foo x="10"><bar x="20"/></foo>,<bar x="20"/>)
    ),
    unit:assert-equals(
        $test:all-matches('/*')(document { <foo x="10"><bar x="20"/></foo> }),
        <foo x="10"><bar x="20"/></foo>
    )
};
