xquery version "3.0";

(:~
 : Tests for xf:at
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

(:~ Simple selector uses descendents axis :)
declare %unit:test function test:simple-selector() {
    unit:assert-equals(xf:at($test:input, 'li'),
        (<li>item <span class="first">1</span></li>,
         <li>item <span>2</span></li>,
         <li>item <span class="last"><i>3</i></span></li>))
};

(:~ Note that root element is not available for explicit selection :)
declare %unit:test function test:id-select() {
    unit:assert-equals(xf:at($test:input, '@id'),
        attribute id { 'xyz' })
};

(:~ But when wrapping it in a document node it is :)
declare %unit:test %unit:ignore('cannot select document root') function test:root-select() {
    unit:assert-equals(xf:at(document { $test:input }, 'ul/@id'),
        <ul id="xyz">
            <li>item <span class="first">1</span></li>
            <li>item <span>2</span></li>
            <li>item <span class="last"><i>3</i></span></li>
        </ul>
    )
};

(:~ Multiple selectors :)
declare %unit:test function test:chain-select() {
    unit:assert-equals(xf:at($test:input, ('li','span')),
        (<span class="first">1</span>,
         <span>2</span>,
         <span class="last"><i>3</i></span>)
    )
};

(:~ Multiple selectors are composed with descendents axis :)
declare %unit:test function test:chain-descendents() {
    unit:assert-equals(xf:at($test:input, ('li','i')),
        <i>3</i>
    )
};

(:~ Nothing matched :)
declare %unit:test function test:chain-with-non-existing-node() {
    unit:assert-equals(xf:at($test:input, ('li','x')),
        ()
    )
};
