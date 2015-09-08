xquery version "3.1";

(:~
 : Origami tests: μ:template
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace μ = 'http://xokomola.com/xquery/origami/mu'
    at '../mu.xqm';

declare %unit:test %unit:ignore function test:template-identity-function() 
{
    unit:assert-equals(
        μ:template(<p><x y="10"/></p>, ())(),
        ['p', ['x', map { 'y': '10' }]],
        'Identity transform'),
      
    unit:assert-equals(
        μ:template(
            <p><x y="10"/></p>, 
            ['*', μ:copy()]
        )(),
        ['p', ['x', map { 'y': '10' }]],
        'Identity transform using copy node transformer')
        
    (: because p already copies this will never hit 'x' rule :)
    (:
    unit:assert-equals(
        μ:template(
            (<p><x y="10"/></p>,<y x="20"/>), 
            (
                ['p', λ:copy()],
                ['x', λ:copy()],
                ['y', λ:copy()]
            )
        )(),
        (<p><x y="10"/></p>,<y x="20"/>),
        'Identity transform using multiple rules'),
    :)
    
    (:
    unit:assert-equals(
        μ:template(
            (<p><x y="10"/></p>,<p><y x="20"/></p>), 
            ['*', function($n,$c) { $n }]
        )(),
        (<p><x y="10"/></p>,<p><y x="20"/></p>),
        'Identity transform using custom node transformer')
    :)
};

(:~
 : A context function will typecheck context arguments and return
 : the context that will be available in the template rules ($c).
 :)
declare %unit:test %unit:ignore
function test:template-context-function() 
{
    unit:assert-equals(
        μ:template(
            <p><x y="10"/></p>, 
            ['p', function($n,$c) { <foo>{ $c }</foo> }]
        )(12),
        <foo>12</foo>,
        "One argument template")
};

(:~
 : A context function will check context data and throw an error when
 : the arguments are not compatible with the context function signature.
 :)
declare %unit:test("expected", "err:XPTY0004") %unit:ignore
function test:template-context-function-argtype-error() 
{
    unit:assert-equals(
        μ:template(
            <p><x y="10"/></p>, 
            ['p', function($n,$c as xs:integer) { <foo>{ $c }</foo> }]
        )('12'),
        <foo>12</foo>,
        "Typed argument")
};
