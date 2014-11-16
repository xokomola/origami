xquery version "3.0";

(:~
 : Origami tests
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare function test:is-template($tpl as map(*)?) {
    unit:assert($tpl instance of map(*) and $tpl('selector') instance of function(*)),
    unit:assert($tpl instance of map(*) and $tpl('fn') instance of function(*))
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
    (: TODO: in 0.2 this was not acceptable, not sure if it should be :)
    test:is-template(xf:template(function($x) { map {} },<foo/>)),
    
    (: a node transformation should take one argument :)
    (: TODO: in 0.2 this was not acceptable, not sure if it should be :)
    test:is-template(xf:template('foo', function($x,$y) { () }))
};

declare %unit:test function test:matches() {
    (: element matching :)
    unit:assert(xf:matches('foo')(<foo/>)),
    unit:assert(not(xf:matches('bar')(<foo/>))),
    unit:assert(xf:matches('*')(<foo/>)),
    unit:assert(not(xf:matches('@foo')(<foo/>))),
    (: attribute matching :)
    unit:assert(xf:matches('@foo')(attribute foo { '' })),
    unit:assert(not(xf:matches('@bar')(attribute foo { '' }))),
    unit:assert(xf:matches('@*')(attribute foo { '' })),
    unit:assert(not(xf:matches('foo')(attribute foo { '' })))
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

declare %unit:test function test:signature-issue() {
    unit:assert-equals(
        xf:transform(
            xf:template('*', function($node) { <X/> }), 
            <foo><bar/></foo>),
            <X/>)
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
    (: TODO: verify if we should allow item()s too :)
    unit:assert-equals(
        xf:transform((
            xf:template('@*', ()),
            xf:template('*', ())
        ))((<x a="10" b="20"/>,<y/>,text { 'howdy' },<z><!-- hi --><z b="30"/></z>)),
        text { 'howdy' })

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
            xf:select('p[@id]')),
        (<p id="1"/>,<p id="2"/>,<p id="3"/>,<p id="4"/>,<p id="5"/>)
    ),
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
            xf:select('.//p[@id]')),
        (<p id="1"/>,<p id="2"/>,<p id="3"/>,<p id="4"/>,<p id="5"/>)
    )    
};

(:~
 : NOTE: There is a bug in 8.0 snapshot that doesn't compile
 :       the obvious xf:select(('ul','li')) correctly.
 :       @see http://www.mail-archive.com/basex-talk%40mailman.uni-konstanz.de/msg05107.html
 :)
declare %unit:test function test:extract-composed() {
    unit:assert-equals(
        xf:extract(xf:select((xf:select('ul'), xf:select('li'))))(
            <div>
                <li>item 1</li>
                <li>item 2</li>
                <ul>
                    <li>item 3</li>
                    <li>item 4</li>
                </ul>
                <li>item 5</li>
            </div>
        ),
        (<li>item 3</li>,<li>item 4</li>))
};

