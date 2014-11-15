xquery version "3.0";

(:~
 : Origami transformer tests
 :)
module namespace test = 'http://xokomola.com/xquery/origami/xform/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami/xform'
    at '../xform.xqm';

declare function test:is-template($tpl as map(*)) {
    unit:assert($tpl('selector') instance of function(*)),
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

declare %unit:test function test:xpath-matches() {
    unit:assert-equals(
        xf:xpath-matches('p')(<foo><p/><p/></foo>),
        (<p/>,<p/>)
    ),
    unit:assert-equals(
        xf:xpath-matches('p[@id="x"]')(<foo><p id="x"/><p/></foo>),
        <p id="x"/>
    ),    
    (: must be in document to use top element in matching :)
    unit:assert-equals(
        xf:xpath-matches('foo/p[@id]')((
            document { <bar><p id="x"/><p/></bar> },
            document { <foo><p id="y"/><p/></foo> })),
        <p id="y"/>
    )
};

declare %unit:test function test:transform-copy() {

    unit:assert-equals(
        xf:transform()(()),
        ()),

    unit:assert-equals(
        xf:transform()(<foo/>),
        (<foo/>)),
    
    unit:assert-equals(
        xf:transform()(<foo>bar</foo>),
        <foo>bar</foo>),
        
    unit:assert-equals(
        xf:transform()(<foo x="10"><bar y="20"/>bla</foo>),
        <foo x="10"><bar y="20"/>bla</foo>),

    unit:assert-equals(
        xf:transform()(<foo x="10"><bar y="20"/><!-- bla --></foo>),
        <foo x="10"><bar y="20"/><!-- bla --></foo>),

    unit:assert-equals(
        xf:transform()(<foo x="10"><bar y="20"/><?target content?></foo>),
        <foo x="10"><bar y="20"/><?target content?></foo>),

    unit:assert-equals(
        xf:transform()((<foo/>,<bar/>,<baz/>)),
        (<foo/>,<bar/>,<baz/>))

};

declare %unit:test function test:transform-remove-nodes() {

    (: remove all elements :)
    unit:assert-equals(
        xf:transform(
            xf:template('*', ())
        )((<x/>,<y/>,<z><z/></z>)),
        ()),

    (: remove some elements :)
    unit:assert-equals(
        xf:transform(
            xf:template('y', ())
        )((<x/>,<y/>,<z><z/></z>)),
        (<x/>,<z><z/></z>)),

    (: remove all attributes :)
    unit:assert-equals(
        xf:transform(
            xf:template('@*', ())
        )((<x a="10" b="20"/>,<y/>,<z><z b="30"/></z>)),
        (<x/>,<y/>,<z><z/></z>)),

    (: remove some attributes :)
    unit:assert-equals(
        xf:transform(
            xf:template('@b', ())
        )((<x a="10" b="20"/>,<y/>,<z><z b="30"/></z>)),
        (<x a="10"/>,<y/>,<z><z/></z>)),

    (: remove all elements and attributes :)
    unit:assert-equals(
        xf:transform((
            xf:template('@*', ()),
            xf:template('*', ())
        ))((<x a="10" b="20"/>,<y/>,<z><z b="30"/></z>)),
        ()),

    (: remove all elements and attributes but leave some others :)
    unit:assert-equals(
        xf:transform((
            xf:template('@*', ()),
            xf:template('*', ())
        ))((<x a="10" b="20"/>,<y/>,'howdy',<z><!-- hi --><z b="30"/></z>)),
        ('howdy'))

};

declare %unit:test function test:transform-custom-match-fn() {

    (: remove all elements that have an attribute named 'x' :)
    unit:assert-equals(
        xf:transform(
            xf:template(
                function($node) { exists($node/@x) },
                ())
        )(<x><y><p x="10"/><p y="20"/></y></x>),
        <x><y><p y="20"/></y></x>)
};

declare %unit:test function test:transform-literal-result-template() {

    (: remove all elements that have an attribute named 'x' :)
    unit:assert-equals(
        xf:transform(
            xf:template('*', <bla/>)
        )((<x/>,<y/>,<z/>)),
        (<bla/>,<bla/>,<bla/>))
};

declare %unit:test function test:transform-namespaces() {

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

declare %unit:test function test:transform-with-input() {

    unit:assert-equals(
        xf:transform(
            xf:template('test:foo', <x/>),
            <foo><test:foo/></foo>),
        <foo><x/></foo>)
};

declare %unit:test function test:transform-document() {

    unit:assert-equals(
        xf:transform(
            xf:template('test:foo', <x/>),
            document { <foo><test:foo/></foo> }),
        document { <foo><x/></foo> })
};

declare %unit:test function test:extract-node-order() {
    (: are nodes returned document order? No! Breadth-firt. :)
    unit:assert-equals(
        xf:extract(
            xf:select('p[@id]'),
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
            </bar>),
        (<p id="1"/>,<p id="5"/>,<p id="2"/>,<p id="3"/>,<p id="4"/>)
    )    
};
