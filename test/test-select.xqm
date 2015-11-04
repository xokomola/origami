xquery version "3.1";

(:~
 : Tests for o:builder()
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami.xqm'; 

declare variable $test:xml :=
    <foo>
        <bar>
            <p>foo</p>
            <p>bar<i>bla</i></p>
        </bar>
        <p>bla</p>
    </foo>;

declare %unit:test %unit:ignore function test:select() 
{
    unit:assert-equals(
        o:select($test:xml, ['p',(1,2),'i']),
        'No argument = identity'
    )
};