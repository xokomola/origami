xquery version "3.0";

(:~
 : Origami tests: xf:environment
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

declare namespace x = 'urn:example';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

(:~
 : In an empty environment the context will equal the nodes
 : passed into the environment function which you can then
 : query.
 :)
declare %unit:test %unit:ignore function test:empty-environment() {
    let $ctx := xf:env(
        map {}
    )
    let $eval := $ctx(<foo/>)
    return
        unit:assert-equals(
            $eval('.'),
            <foo/>
        ) 
};

(:~
 : If your query doesn't use a namespace then you do not have to
 : define it on the environment if the namespace nodes are already
 : present in the context nodes.
 :)
declare %unit:test %unit:ignore function test:namespace-on-nodes-environment() {
    let $ctx := xf:env(
        map {}
    )
    let $eval := $ctx(<x:foo/>)
    return (
        unit:assert-equals(
            $eval('.'),
            <x:foo/>
        )
    )
};

(:~
 : To declare functions or variables in your eval environment you need to
 : pass them in as a bindings map.
 : Note that you always have to pass in context nodes argument even if empty
 :)
declare %unit:test %unit:ignore function test:var-environment() {
    let $ctx := xf:env(
        map { 'bindings': map {'x': 10} }
    )
    let $eval := $ctx(())
    return
        unit:assert-equals(
            $eval('$x'),
            10
        )
};
 
