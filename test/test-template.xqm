xquery version "3.0";

(:~
 : Origami tests: xf:template
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare %unit:test function test:template-identity-function() 
{
    unit:assert-equals(
        xf:template(<p><x y="10"/></p>)(),
        <p><x y="10"/></p>,
        'Identity transform'),
        
    unit:assert-equals(
        xf:template((<p><x y="10"/></p>,<p><y x="20"/></p>))(),
        (<p><x y="10"/></p>,<p><y x="20"/></p>),
        'Identity transform multiple root elements'),
        
    unit:assert-equals(
        xf:template(
            (<p><x y="10"/></p>,<p><y x="20"/></p>), 
            ['*', xf:copy()]
        )(),
        (<p><x y="10"/></p>,<p><y x="20"/></p>),
        'Identity transform using copy node transformer'),

    (: because p already copies this will never hit 'x' rule :)
    unit:assert-equals(
        xf:template(
            (<p><x y="10"/></p>,<y x="20"/>), 
            (
                ['p', xf:copy()],
                ['x', xf:copy()],
                ['y', xf:copy()]
            )
        )(),
        (<p><x y="10"/></p>,<y x="20"/>),
        'Identity transform using multiple rules'),

    unit:assert-equals(
        xf:template(
            (<p><x y="10"/></p>,<p><y x="20"/></p>), 
            ['*', function($n,$c) { $n }]
        )(),
        (<p><x y="10"/></p>,<p><y x="20"/></p>),
        'Identity transform using custom node transformer')

};

(:~
 : A context function will typecheck context arguments and return
 : the context that will be available in the template rules ($c).
 :)
declare %unit:test function test:template-context-function() 
{
    unit:assert-equals(
        xf:template(
            <p><x y="10"/></p>, 
            ['p', function($n,$c) { <foo>{ $c }</foo> }],
            function($a as xs:integer,$b as xs:integer) { $a * $b })(2,6),
        <foo>12</foo>,
        'Arity 2 context function that calculates a context value')
};

(:~
 : A context function will check context data and throw an error when
 : the arguments are not compatible with the context function signature.
 :)
declare %unit:test("expected", "err:XPTY0004") 
function test:template-context-function-argtype-error() 
{
    unit:assert-equals(
        xf:template(
            <p><x y="10"/></p>, 
            ['p', function($n,$c) { <foo>{ $c }</foo> }],
            function($a as xs:integer,$b as xs:integer) { $a * $b })('4',6),
        <foo>12</foo>,
        'Should raise: Cannot promote xs:string to xs:integer: "4".')
};

(:~
 : A template only supports a context function with up to 6 arguments.
 : If you need more consider using a different data type such as a map
 : array or node sequence.
 :)
declare %unit:test("expected", "err:XPDY0002") 
function test:template-context-function-too-many-arguments() 
{
    unit:assert-equals(
        xf:template(
            <p><x y="10"/></p>, 
            ['p', function($n,$c) { <foo>{ $c }</foo> }],
            function($a,$b,$c,$d,$e,$f,$g) { $a * $b })(2,6),
        <foo>12</foo>,
        'More than 6 arguments are not accepted')
};

