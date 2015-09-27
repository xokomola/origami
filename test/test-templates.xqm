xquery version "3.1";

(:~
 : Origami tests: o:template
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami'
    at '../origami.xqm';

declare %unit:test function test:template-identity-function() 
{
    unit:assert-equals(
        o:apply(o:template(<p><x y="10"/></p>, ())),
        ['p', ['x', map { 'y': '10' }]],
        'Identity transform'
    ),
      
    unit:assert-equals(
        o:apply(o:template(
            <p><x y="10"/></p>, 
            ['*', o:copy()]
        )),
        ['p', ['x', map { 'y': '10' }]],
        'Identity transform using copy node transformer'
    ),
        
    (: because p already copies this will never hit 'x' rule :)
    unit:assert-equals(
        o:apply(o:template(
            <doc><p><x y="10"/></p><y x="20"/></doc>, 
            (
                ['p', o:copy()],
                ['x', o:copy()],
                ['y', o:copy()]
            )
        )),
        ['doc', ['p', ['x', map { 'y': '10' }]],['y', map { 'x': '20' }]],
        'Identity transform using multiple rules'
    ),
    
    unit:assert-equals(
        o:apply(o:template(
            ['doc', ['p', ['x', map { 'y': '10' }]],['p', ['y', map { 'x': '20' }]]], 
            ['*', function($n) { $n }]
        )),
        ['doc', ['p', ['x', map { 'y': '10' }]],['p', ['y', map { 'x': '20' }]]],
        'Identity transform using custom node transformer and with mu-doc as input'
    )
};

(:~
 : A context function will typecheck context arguments and return
 : the context that will be available in the template rules ($c).
 :)
declare %unit:test function test:template-context-function() 
{
    unit:assert-equals(
        o:apply(o:template(
            <p><x y="10"/></p>, 
            ['p', function($n,$c) { ['foo', $c] }]
        ), 12),
        ['foo', 12],
        "One argument template"
    ),
    
    unit:assert-equals(
        o:apply(o:template(
            <p><x y="10"/></p>, 
            ['p', function($n,$c) { <foo>{ $c }</foo> }]
        ), 12),
        <foo>12</foo>,
        "One argument template producing XML element node")
};
