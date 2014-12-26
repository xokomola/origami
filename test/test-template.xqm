xquery version "3.0";

(:~
 : Origami tests: xf:template
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare %unit:test function test:template-function-arity() {
    unit:assert(
        function-arity(xf:template(<template/>)) = 0,
        'An empty-sequence model returns a template function with arity 0'),
    unit:assert(
        function-arity(xf:template(<template/>,())) = 0,
        'An empty-sequence model returns a template function with arity 0'),
    unit:assert(
        function-arity(xf:template(<template/>,(),())) = 0,
        'An empty-sequence model returns a template function with arity 0'),
    unit:assert(
        function-arity(xf:template(<template/>,(),function() { () })) = 0,
        'An arity 0 model function returns a template function with arity 0'),
    unit:assert(
        function-arity(xf:template(<template/>,(),function($a) { () })) = 1,
        'An arity 1 model function returns a template function with arity 1'),
    unit:assert(
        function-arity(xf:template(<template/>,(),function($a,$b) { () })) = 2,
        'An arity 2 model function returns a template function with arity 2'),
    unit:assert(
        function-arity(xf:template(<template/>,(),function($a,$b,$c) { () })) = 3,
        'An arity 3 model function returns a template function with arity 3'),
    unit:assert(
        function-arity(xf:template(<template/>,(),function($a,$b,$c,$d) { () })) = 4,
        'An arity 4 model function returns a template function with arity 4')
};

declare %unit:test("expected", "XPDY0002") function test:ArityNotSupportedError() {
    unit:assert(
        xf:template(<template/>, function($a,$b,$c,$e,$f) { () })
            instance of function(*),
        'A model function with more than 4 arguments raises 
        xf:ArityNotSupportedError')
};

declare %unit:test function test:template-identity-function() {
    unit:assert-equals(
        xf:template(<p><x y="10"/></p>)(),
        <p><x y="10"/></p>,
        'One argument template returns the same template'),
    unit:assert-equals(
        xf:template(<p><x y="10"/></p>,['x'],())(),
        <x y="10"/>,
        'Selector and empty model selects some nodes and returns them 
        unmodified')
};

declare %unit:test function test:template-model-array-seq() {
    unit:assert-equals(
        xf:template(
            <p><x y="10"/></p>,
            ['x']
        )(),
        <p><x y="10"/></p>,
        'A model with only a selector will not transform anything'),
    unit:assert-equals(
        xf:template(
            <p><x y="10"/></p>,
            ['x', xf:rename('a')]
        )(),
        <p><a y="10"/></p>,
        'A model with a rule that renames x to a'),
    unit:assert-equals(
        xf:template(
            document { <p><x y="10"/></p> },
            (
                ['x', xf:rename('a')],
                ['p', xf:rename('b'), xf:apply() ]
            )
        )(),
        document { <b><a y="10"/></b> },
        'A model with rules that rename x to a and p to b')
};

declare %unit:test("expected", "XPDY0002") function test:InvalidModelError() {
    unit:assert(
        xf:template(<template/>, 'foo')
            instance of function(*),
        'A model argument that is not a function a sequence of arrays or an 
        empty sequences raises xf:InvalidModelError')
};
