xquery version "3.1";

(:~
 : Tests for o:select()
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace o = 'http://xokomola.com/xquery/origami' 
    at '../origami.xqm'; 

(: TODO: finish implementation :)

declare variable $test:mu := o:doc(
    <foo>
        <bar>
            <p>foo<i><b>bla</b></i></p>
            <p>bar<i>bla</i></p>
        </bar>
        <p>bla</p>
    </foo>);

declare %unit:test function test:select() 
{
    unit:assert-equals(
        o:select($test:mu, ['foo']),
        $test:mu,
        "Select whole document"
    ),

    unit:assert-equals(
        o:select($test:mu, []),
        (),
        "Select nothing"
    ),

    unit:assert-equals(
        o:select($test:mu, ['p']),
        (['p', 'foo', ['i', ['b', 'bla']]], ['p', 'bar', ['i', 'bla']],['p', 'bla']),
        "Select all p elements"
    ),

    unit:assert-equals(
        o:xml(['x', o:select($test:mu, ['p'])]),
        <x>
            <p>foo<i><b>bla</b></i></p>
            <p>bar<i>bla</i></p>
            <p>bla</p>
        </x>,
        "Select all p elements and convert to xml"
    ),

    unit:assert-equals(
        o:select($test:mu, ['p','i']),
        (['i', ['b', 'bla']], ['i', 'bla']),
        "Select all p//i elements"
    ),

    unit:assert-equals(
        o:select($test:mu, ['p','b']),
        ['b', 'bla'],
        "Select all p//b elements"
    ),

    unit:assert-equals(
        o:select($test:mu, ['p',('i','b')]),
        (['i', ['b', 'bla']], ['i', 'bla']),
        "Select all p//(i|b) elements"
    ),

    unit:assert-equals(
        o:select($test:mu, ['p',1]),
        (),
        "Non-string step will never match anything"
    )

};
