xquery version "3.0";

(:~
 : Tests for xf:do
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

(:~ Test nodes :)
declare variable $test:input := 
        <ul id="xyz">
            <li>item <span class="first">1</span></li>
            <li>item <span>2</span></li>
            <li>item <span class="last"><i>3</i></span></li>
        </ul>;

(:~ Transform node sequence :)
declare %unit:test function test:do() {
    unit:assert-equals(
        xf:do($test:input//li, [
            function($n) {
                (<a/>,<b/>)
            },
            function($n) {
                element n { $n }                
            }
        ]),
        <n><a/><b/></n>
    )
};
