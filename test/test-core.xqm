xquery version "3.0";

(:~
 : Origami tests
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare function test:is-template($tpl as map(*)?) {
    unit:assert($tpl instance of map(*) and $tpl('select') instance of function(*)),
    unit:assert($tpl instance of map(*) and $tpl('fn') instance of function(*))
};

declare %unit:test %unit:ignore('TODO') function test:template() {
    test:is-template(xf:at('foo', function($node) { () })),
    test:is-template(xf:at('foo', <foo/>)),
    test:is-template(xf:at(function($x) { true() }, <foo/>)),
    (: should this raise an error? :)
    (: TODO: review this :)
    test:is-template(xf:template(1,<foo/>)),
    (: a selector function must return a boolean :)
    (: TODO: in 0.2 this was not acceptable, not sure if it should be :)
    test:is-template(xf:template(function($x) { map {} },<foo/>)),
    
    (: a node transformation should take one argument :)
    (: TODO: in 0.2 this was not acceptable, not sure if it should be :)
    test:is-template(xf:template('foo', function($x,$y) { () }))
};
