xquery version "3.0";

(:~
 : Origami tests
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare %unit:test %unit:ignore('TODO') function test:transform-simple() {
    unit:assert-equals(
        xf:transform((
            xf:template('p[@x]', function($node) { element bar { $node/@* }}),
            xf:template('p', function($node) { <foo/> } )),
        <div><p x="1">hello</p><p/><p x="2"/><p/></div>),
        <div><bar x="1"/><foo/><bar x="2"/><foo/></div>)
};

declare %unit:test %unit:ignore('TODO') function test:transform-copy() {

    unit:assert-equals(
        xf:transform((),()),
        ()),

    unit:assert-equals(
        xf:transform((),<foo/>),
        (<foo/>)),
    
    unit:assert-equals(
        xf:transform((),<foo>bar</foo>),
        <foo>bar</foo>),
        
    unit:assert-equals(
        xf:transform((),<foo x="10"><bar y="20"/>bla</foo>),
        <foo x="10"><bar y="20"/>bla</foo>),

    unit:assert-equals(
        xf:transform((),<foo x="10"><bar y="20"/><!-- bla --></foo>),
        <foo x="10"><bar y="20"/><!-- bla --></foo>),

    unit:assert-equals(
        xf:transform((),<foo x="10"><bar y="20"/><?target content?></foo>),
        <foo x="10"><bar y="20"/><?target content?></foo>),

    unit:assert-equals(
        xf:transform((),(<foo/>,<bar/>,<baz/>)),
        (<foo/>,<bar/>,<baz/>))
        
};

declare %unit:test %unit:ignore('TODO') function test:transform-remove-nodes() {

    (: remove all elements :)
    unit:assert-equals(
        xf:transform(
            xf:template('y', ()),
            <x><y/></x>),
        <x/>),
        
 
    (: remove some elements :)
    (: NOTE: the top element can only be removed with a self::y :)
    unit:assert-equals(
        xf:transform(
            xf:template('y', ()),
        (<x><y/></x>,<y/>,<z><z/></z>)),
        (<x/>,<y/>,<z><z/></z>)),

    unit:assert-equals(
        xf:transform((
            xf:template('y', ()),
            xf:template('self::y', ())),
        (<x><y/></x>,<y/>,<z><z/></z>)),
        (<x/>,<z><z/></z>)),

    (: remove all attributes :)
    unit:assert-equals(
        xf:transform(
            xf:template('@*', ()),
        (<x a="10" b="20"/>,<y/>,<z><z b="30"/></z>)),
        (<x/>,<y/>,<z><z/></z>)),

    (: remove some attributes :)
    unit:assert-equals(
        xf:transform(
            xf:template('@b', ()),
        (<x a="10" b="20"/>,<y/>,<z><z b="30"/></z>)),
        (<x a="10"/>,<y/>,<z><z/></z>)),

    (: remove all elements and attributes :)
    (: NOTE: again the self::* is needed to remove top-level nodes :)
    unit:assert-equals(
        xf:transform((
            xf:template('@*', ()),
            xf:template('self::*', ())
        ),(<x a="10" b="20"/>,<y/>,<z><z b="30"/></z>)),
        ()),

    (: remove all elements and attributes but leave some others :)
    (: TODO: verify if item()s should be allowed too :)

    unit:assert-equals(
        xf:transform((
            xf:template('@*', ()),
            xf:template('self::*', ())
        ))((<x a="10" b="20"/>,<y/>,text { 'howdy' },<z><!-- hi --><z b="30"/></z>)),
        text { 'howdy' })

};

declare %unit:test %unit:ignore('TODO') function test:transform-custom-match-fn() {

    (: remove all elements that have an attribute named 'x' :)
    (: TODO: in a transform the custom fn should return the node itself :)
    (:       this is different from extractors where it should return a boolean :)
    (:       maybe this should be changed so extractors can use the same fn :)
    (:       in an extractor the function body should be exist($node/@x) :)
    unit:assert-equals(
        xf:transform(
            xf:template(
                function($node) { $node[@x] },
                ())
        )(<x><y><p x="10"/><p y="20"/></y></x>),
        <x><y><p y="20"/></y></x>)
};

declare %unit:test %unit:ignore('TODO') function test:transform-literal-result-template() {

    (: remove all elements that have an attribute named 'x' :)
    unit:assert-equals(
        xf:transform(
            xf:template('self::*', <bla/>)
        )((<x/>,<y/>,<z/>)),
        (<bla/>,<bla/>,<bla/>))
};

declare %unit:test %unit:ignore('NS not supported yet') function test:transform-namespaces() {

    (: handle namespaced elements :)
    unit:assert-equals(
        xf:transform(
            xf:template('test:foo', <x/>)
        )(<foo><test:foo/></foo>),
        <foo><x/></foo>),
        
    unit:assert-equals(
        xf:transform(
            xf:template('x', <x:foo xmlns:x="urn:foo"/>),
            <foo><x/></foo>
        ),
        <foo><y:foo xmlns:y="urn:foo"/></foo>)       

};

declare %unit:test %unit:ignore('NS not supported yet') function test:transform-document() {

    unit:assert-equals(
        xf:transform(
            xf:template('test:foo', <x/>),
            document { <foo><test:foo/></foo> }),
        document { <foo><x/></foo> })
};
