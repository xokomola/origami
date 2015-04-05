xquery version "3.0";

(:~
 : Origami tests: xf:environment
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

declare namespace x = 'urn:example';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

(:~
 : Empty context uses default environment which has no context nodes set.
 :)
declare %unit:test %unit:ignore function test:empty-context() {
    unit:assert-equals(
        xf:context()('bindings')(''),
        ()
    ) 
};

declare %unit:test %unit:ignore function test:context-nodes() {
    (: bind context to a node :)
    unit:assert-equals(
        xf:context(<foo/>)('bindings')(''),
        <foo/>
    ),
    (: bind context to nodes :)
    unit:assert-equals(
        xf:context((<foo/>,<bar/>))('bindings')(''),
        (<foo/>,<bar/>)
    ),
    (: re-bind context node :)
    unit:assert-equals(
        xf:context(<bla/>, xf:context((<foo/>,<bar/>)))('bindings')(''),
        <bla/>
    ),    
    (: empty an existing context :)
    unit:assert-equals(
        xf:context((), xf:context((<foo/>,<bar/>)))('bindings')(''),
        ()
    )    
};
