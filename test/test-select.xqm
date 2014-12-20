xquery version "3.0";

(:~
 : Tests for eval environments.
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare %unit:test function test:expr-environment() {
    unit:assert-equals(
        xf:select('@x')(<foo x="10"/>),
        attribute x { '10' }
    ),
    unit:assert-equals(
        xf:select('@x')(<foo x="10"><bar x="20"/></foo>),
        attribute x { '10' }
    ),
    unit:assert-equals(
        xf:select('.')(<foo x="10"><bar x="20"/></foo>),
        <foo x="10"><bar x="20"/></foo>
    ),
    unit:assert-equals(
        xf:select('/*')(document { <foo x="10"><bar x="20"/></foo> }),
        <foo x="10"><bar x="20"/></foo>
    )
};

declare %unit:test function test:environment() {
    unit:assert-equals(
        xf:select-all('@x')(<foo x="10"/>),
        attribute x { '10' }
    ),
    unit:assert-equals(
        xf:select-all('@x')(<foo x="10"><bar x="20"/></foo>),
        (attribute x { '10' }, attribute x { '20' })
    ),
    unit:assert-equals(
        xf:select-all('.')(<foo x="10"><bar x="20"/></foo>),
        (<foo x="10"><bar x="20"/></foo>,<bar x="20"/>)
    ),
    unit:assert-equals(
        xf:select-all('/*')(document { <foo x="10"><bar x="20"/></foo> }),
        <foo x="10"><bar x="20"/></foo>
    )
};
