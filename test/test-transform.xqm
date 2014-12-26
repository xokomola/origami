xquery version "3.0";

(:~
 : Origami tests: xf:transform
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare %unit:test function test:transform-simple() {
    unit:assert-equals(
        xf:transform(
            <div><p x="1">hello</p><p/><p x="2"/><p/></div>, 
            (
                ['p[@x]', function($node) { element bar { $node/@* }}],
                ['p', function($node) { <foo/> }]
            )
        ),
        <div><bar x="1"/><foo/><bar x="2"/><foo/></div>,
        'Transform rule functions are executed to produce output nodes')
};

declare %unit:test function test:transform-identity-copy() {

    unit:assert-equals(
        xf:transform((),()),
        ()),

    unit:assert-equals(
        xf:transform(<foo/>, ()),
        (<foo/>)),
    
    unit:assert-equals(
        xf:transform(<foo>bar</foo>, ()),
        <foo>bar</foo>),
        
    unit:assert-equals(
        xf:transform(<foo x="10"><bar y="20"/>bla</foo>, ()),
        <foo x="10"><bar y="20"/>bla</foo>),

    unit:assert-equals(
        xf:transform(<foo x="10"><bar y="20"/><!-- bla --></foo>, ()),
        <foo x="10"><bar y="20"/><!-- bla --></foo>),

    unit:assert-equals(
        xf:transform(<foo x="10"><bar y="20"/><?target content?></foo>, ()),
        <foo x="10"><bar y="20"/><?target content?></foo>),

    unit:assert-equals(
        xf:transform((<foo/>,<bar/>,<baz/>), ()),
        (<foo/>,<bar/>,<baz/>))
        
};

declare %unit:test function test:transform-remove-nodes() {

    unit:assert-equals(
        xf:transform(
            <x><y/></x>,
            ['*', ()]
        ),
        <x/>,
        'Removes all elements, except top-level'),
        
    unit:assert-equals(
        xf:transform(
            document { <x><y/></x> },
            ['*', ()]
        ),
        document { () },
        'Removes all elements, except top-level'),
         
    unit:assert-equals(
        xf:transform(
            (<x><y/></x>,<y/>,<z><z/></z>),
            ['y', ()]
        ),
        (<x/>,<y/>,<z><z/></z>),
        'Removes all y-elements, except if it is top-level'),

    unit:assert-equals(
        xf:transform(
            (<x><y/></x>,<y/>,<z><z/></z>),
            (
                ['y', ()],
                ['self::y', ()]
            )
        ),
        (<x/>,<z><z/></z>),
        'Removes all y-elements, including top-level due to self::y'),

    unit:assert-equals(
        xf:transform(
            (<x a="10" b="20"/>,<y/>,<z><z b="30"/></z>),
            ['@*', ()]
        ),
        (<x/>,<y/>,<z><z/></z>),
        'Removes all attributes'),

    unit:assert-equals(
        xf:transform(
            (<x a="10" b="20"/>,<y/>,<z><z b="30"/></z>),
            ['@b', ()]
        ),
        (<x a="10"/>,<y/>,<z><z/></z>),
        'Removes all b-attributes'),

    unit:assert-equals(
        xf:transform(
            (<x a="10" b="20"/>,<y/>,<z><z b="30"/></z>),
            ['self::*', ()]
        ),
        (),
        'Removes all elements'),

    unit:assert-equals(
        xf:transform(
            (<x a="10" b="20"/>,<y/>,text { 'howdy' },<z><!-- hi --><z b="30"/></z>),
            ['self::*', ()]
        ),
        text { 'howdy' },
        'Removes all elements but leaves other nodes')

};

declare %unit:test function test:transform-custom-match-fn() {

    unit:assert-equals(
        xf:transform(
            <x><y><p x="10"/><p y="20"/></y></x>,
            [
                function($node) { $node[@x] },   (: select nodes :)
                ()                               (: remove them  :)
            ]
        ),
        <x><y><p y="20"/></y></x>,
        'A custom selector function returns the nodes, the empty sequence 
        removes them')
};

declare %unit:test function test:transform-literal-result-template() {

    unit:assert-equals(
        xf:transform(
            (<x/>,<y/>,<z/>),
            ['self::*', <bla/>]
        ),
        (<bla/>,<bla/>,<bla/>),
        'Replace all elements with bla-element'
    )
};

declare %unit:test %unit:ignore('NS not supported yet') function test:transform-namespaces() {

    unit:assert-equals(
        xf:transform(
            <foo><test:foo/></foo>,
            ['test:foo', <x/>]
        ),
        <foo><x/></foo>
    ),
        
    unit:assert-equals(
        xf:transform(
            <foo><x/></foo>,
            ['x', <x:foo xmlns:x="urn:foo"/>]
            
        ),
        <foo><y:foo xmlns:y="urn:foo"/></foo>)       

};

declare %unit:test %unit:ignore('NS not supported yet') function test:transform-document() {

    unit:assert-equals(
        xf:transform(
            document { <foo><test:foo/></foo> },
            ['test:foo', <x/>]
        ),
        document { <foo><x/></foo> }
    )
};
