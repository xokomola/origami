xquery version "3.0";

(:~
 : Origami tests: xf:extract
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare %unit:test function test:extract-document-order() {

    unit:assert-equals(
        xf:extract(
            <bar>
                <p id="1"/>
                <p/>
                <foo>
                    <p id="2"/>
                    <p id="3"/>
                </foo>
                <bla>
                    <bar>
                        <p id="4"/>
                    </bar>
                </bla>
                <p id="5"/>
            </bar>,        
            ['p[@id]']
        ),
        (<p id="1"/>,<p id="2"/>,<p id="3"/>,<p id="4"/>,<p id="5"/>),
        'Nodes are extracted in document order and no duplicates'),
    
    unit:assert-equals(
        xf:extract(
            <bar>
                <p id="1"/>
                <p/>
                <foo>
                    <p id="2"/>
                    <p id="3"/>
                </foo>
                <bla>
                    <bar>
                        <p id="4"/>
                    </bar>
                </bla>
                <p id="5"/>
            </bar>,
            ['.//p[@id]']
        ),
        (<p id="1"/>,<p id="2"/>,<p id="3"/>,<p id="4"/>,<p id="5"/>),
        'Using descendant axis is not necessary and achieves the same as p[@id]')    
};

declare %unit:test function test:extract-select-and-transform() {
       
    unit:assert-equals(
        xf:extract(
            <div>
                <li>item 1</li>
                <li>item 2</li>
                <ul>
                    <li>item 3</li>
                    <li>item 4</li>
                </ul>
                <li>item 5</li>
            </div>,
            ['ul/li', xf:wrap(<x/>)]
        ),
        (<x><li>item 3</li></x>,<x><li>item 4</li></x>))
};

declare %unit:test function test:extract-custom-match-fn() {

    unit:assert-equals(
        xf:extract(
            <x><y><p x="10"/><p y="20"/></y></x>,
            [
                function($node) { $node[@x] },   (: select nodes :)
                ()                               (: remove them  :)
            ]
        ),
        (),
        'A custom selector function returns the nodes, but as the transform 
        empties it the result will be empty')
};

declare %unit:test function test:extract-literal-result-template() {

    (: previously this eliminated all but one <bla/> element as each
       invocation of the rule returned the same element and therefore
       inner/outermost used by the extract functions would eliminate
       all but one. This is now fixed and each invocation will return
       a copy of the <bla/> node, hence three different <bla/> elements :)
       
    unit:assert-equals(
        xf:extract(
            (<x/>,<y/>,<z/>),
            ['self::*', <bla/>]
        ),
        (<bla/>,<bla/>,<bla/>),
        'Extract all elements but replace them with bla-element')

};

declare %unit:test function test:node-identity-and-extract() {
    
    unit:assert-equals(
         document { <p><a y="10"/></p> } =>
         xf:extract((
            ['a'],
            ['p[a]']
         )),
         <p><a y="10"/></p>,
         'xf:extract(-outer) returns the outermost nodes'),

    unit:assert-equals(
         document { <p><a y="10"/></p> } =>
         xf:extract((
            ['a'],
            ['p[a]', <foo/>]
         )),
         (<a y="10"/>,<foo/>),
         'xf:extract(-outer) foo is a new element')

};
