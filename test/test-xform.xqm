xquery version "3.0";

(:~
 : Origami transformer tests
 :)
module namespace test = 'http://xokomola.com/xquery/origami/xform/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami/xform'
    at '../xform.xqm';

declare function test:is-template($tpl as map(*)) {
    unit:assert($tpl('match') instance of function(*)),
    unit:assert($tpl('fn') instance of function(*))
};

declare %unit:test function test:template() {
    test:is-template(xf:template('foo', function($node) { () })),
    test:is-template(xf:template('foo', <foo/>)),
    test:is-template(xf:template(function($x) { true() }, <foo/>)),
    (: should this raise an error? :)
    unit:assert-equals(
        xf:template(1,<foo/>),
        ()
    ),
    (: a selector function must return a boolean :)
    unit:assert-equals(
        xf:template(function($x) { map {} },<foo/>),
        ()
    ),
    (: a node transformation should take one argument :)
    unit:assert-equals(
        xf:template('foo', function($x,$y) { () }),
        ()
    )
};

declare %unit:test function test:matches() {
    (: element matching :)
    unit:assert(xf:matches(<foo/>, 'foo')),
    unit:assert(not(xf:matches(<foo/>, 'bar'))),
    unit:assert(xf:matches(<foo/>, '*')),
    unit:assert(not(xf:matches(<foo/>,'@foo'))),
    (: attribute matching :)
    unit:assert(xf:matches(attribute foo { '' }, '@foo')),
    unit:assert(not(xf:matches(attribute foo { '' }, '@bar'))),
    unit:assert(xf:matches(attribute foo { '' }, '@*')),
    unit:assert(not(xf:matches(attribute foo { '' }, 'foo')))
};

declare %unit:test function test:xform-copy() {

    unit:assert-equals(
        xf:xform()(()),
        ()),

    unit:assert-equals(
        xf:xform()(<foo/>),
        (<foo/>)),
    
    unit:assert-equals(
        xf:xform()(<foo>bar</foo>),
        <foo>bar</foo>),
        
    unit:assert-equals(
        xf:xform()(<foo x="10"><bar y="20"/>bla</foo>),
        <foo x="10"><bar y="20"/>bla</foo>),

    unit:assert-equals(
        xf:xform()(<foo x="10"><bar y="20"/><!-- bla --></foo>),
        <foo x="10"><bar y="20"/><!-- bla --></foo>),

    unit:assert-equals(
        xf:xform()(<foo x="10"><bar y="20"/><?target content?></foo>),
        <foo x="10"><bar y="20"/><?target content?></foo>),

    unit:assert-equals(
        xf:xform()((<foo/>,<bar/>,<baz/>)),
        (<foo/>,<bar/>,<baz/>))

};

declare %unit:test function test:xform-remove-nodes() {

    (: remove all elements :)
    unit:assert-equals(
        xf:xform(
            xf:template('*', ())
        )((<x/>,<y/>,<z><z/></z>)),
        ()),

    (: remove some elements :)
    unit:assert-equals(
        xf:xform(
            xf:template('y', ())
        )((<x/>,<y/>,<z><z/></z>)),
        (<x/>,<z><z/></z>)),

    (: remove all attributes :)
    unit:assert-equals(
        xf:xform(
            xf:template('@*', ())
        )((<x a="10" b="20"/>,<y/>,<z><z b="30"/></z>)),
        (<x/>,<y/>,<z><z/></z>)),

    (: remove some attributes :)
    unit:assert-equals(
        xf:xform(
            xf:template('@b', ())
        )((<x a="10" b="20"/>,<y/>,<z><z b="30"/></z>)),
        (<x a="10"/>,<y/>,<z><z/></z>)),

    (: remove all elements and attributes :)
    unit:assert-equals(
        xf:xform((
            xf:template('@*', ()),
            xf:template('*', ())
        ))((<x a="10" b="20"/>,<y/>,<z><z b="30"/></z>)),
        ()),

    (: remove all elements and attributes but leave some others :)
    unit:assert-equals(
        xf:xform((
            xf:template('@*', ()),
            xf:template('*', ())
        ))((<x a="10" b="20"/>,<y/>,'howdy',<z><!-- hi --><z b="30"/></z>)),
        ('howdy'))

};

declare %unit:test function test:xform-custom-match-fn() {

    (: remove all elements that have an attribute named 'x' :)
    unit:assert-equals(
        xf:xform(
            xf:template(
                function($node) { exists($node/@x) },
                ())
        )(<x><y><p x="10"/><p y="20"/></y></x>),
        <x><y><p y="20"/></y></x>)
};

declare %unit:test function test:xform-literal-result-template() {

    (: remove all elements that have an attribute named 'x' :)
    unit:assert-equals(
        xf:xform(
            xf:template('*', <bla/>)
        )((<x/>,<y/>,<z/>)),
        (<bla/>,<bla/>,<bla/>))
};

declare %unit:test function test:xform-namespaces() {

    (: handle namespaced elements :)
    unit:assert-equals(
        xf:xform(
            xf:template('test:foo', <x/>)
        )(<foo><test:foo/></foo>),
        <foo><x/></foo>),
        
    unit:assert-equals(
        xf:xform(
            xf:template('x', <x:foo xmlns:x="urn:foo"/>),
            <foo><x/></foo>
        ),
        <foo><y:foo xmlns:y="urn:foo"/></foo>)       

};

declare %unit:test function test:xform-with-input() {

    unit:assert-equals(
        xf:xform(
            xf:template('test:foo', <x/>),
            <foo><test:foo/></foo>),
        <foo><x/></foo>)
};
