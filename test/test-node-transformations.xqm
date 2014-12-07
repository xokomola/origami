xquery version "3.0";

(:~
 : Tests for xf:do
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

(:~ `xf:do` :)
declare %unit:test function test:do() {
    unit:assert-equals(
        xf:do((<a/>,<a/>), (
            xf:wrap(<b/>),
            xf:wrap(<c/>)
        )),
        (<c>
            <b>
                <a/>
                <a/>
            </b>
        </c>)
    )
};

(:~ `xf:each` :)
declare %unit:test function test:each() {
    unit:assert-equals(
        xf:do-each((<a/>,<a/>), (
            xf:wrap(<b/>),
            xf:wrap(<c/>)
        )),
        (<c>
            <b>
                <a/>
            </b>
        </c>,
        <c>
            <b>
                <a/>
            </b>
        </c>)
    )
};

(:~ Using the arrow operator works like `xf:do` :)
declare %unit:test function test:arrow-operator-as-do() {
    unit:assert-equals(
        (<a/>,<a/>) => xf:wrap(<b/>) => xf:wrap(<c/>),
        (<c>
            <b>
                <a/>
                <a/>
            </b>
        </c>)
    )
};

(:~ To provide `xf:each` semantics do the following :)
declare %unit:test function test:table() {
    let $input :=
        <table>
            <tr><td>A</td><td>10</td></tr>
            <tr><td>B</td><td>20</td></tr>
            <tr><td>C</td><td>30</td></tr>
        </table>
    return (
        unit:assert-equals(
            $input => xf:at('td') => 
                xf:do-each(
                    (xf:wrap(<b/>), xf:content(text { 'x' }))
                ),
            (<b>x</b>,
             <b>x</b>,
             <b>x</b>,
             <b>x</b>,
             <b>x</b>,
             <b>x</b>)
        ),
        unit:assert-equals(
            xf:at('td[2]')($input) => 
                xf:do-each(function($n) { 
                    xf:content($n, text { xs:integer($n/text()) * 2 } )
                }),
            (<td>20</td>,<td>40</td>,<td>60</td>))
    )
};

