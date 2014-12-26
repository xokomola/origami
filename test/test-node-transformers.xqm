xquery version "3.0";

(:~
 : Tests for node transformers.
 :)
module namespace test = 'http://xokomola.com/xquery/origami/tests';

import module namespace xf = 'http://xokomola.com/xquery/origami'
    at '../core.xqm';

declare %unit:test function test:wrap() {
    (: wrap an element :)
    unit:assert-equals(
        xf:wrap(<a/>,<b/>),
        <b><a/></b>
    ),
    (: wrap with an element with attribute :)
    unit:assert-equals(
        xf:wrap(<a/>,<b x="1"/>),
        <b x="1"><a/></b>
    ),
    (: wrap with an element, only uses the outer element :)
    unit:assert-equals(
        xf:wrap(<a/>,<b><c/></b>),
        <b><a/></b>
    ),
    (: wrap a sequence of nodes :)
    unit:assert-equals(
        xf:wrap((<a/>,<a/>),<b/>),
        <b><a/><a/></b>
    ),
    (: wrap a text node :)
    unit:assert-equals(
        xf:wrap(text { 'hello' },<b/>),
        <b>hello</b>
    ),
    (: comments can be wrapped too, any type of node really :)
    unit:assert-equals(
        xf:wrap(<!-- bla -->,<b/>),
        <b><!-- bla --></b>
    ),
    (: with an empty sequence there is nothing to wrap :)
    unit:assert-equals(
        xf:wrap((),<b/>),
        ()
    )
};

declare %unit:test function test:unwrap() {
    (: unwrap an element :)
    unit:assert-equals(
        xf:unwrap(<b><a/></b>),
        <a/>
    ),
    (: unwrap an empty element :)
    unit:assert-equals(
        xf:unwrap(<a/>),
        ()
    ),
    (: empty sequence is passed through :)
    unit:assert-equals(
        xf:unwrap(()),
        ()
    ),
    (: unwrap an element with text :)
    unit:assert-equals(
        xf:unwrap(<a>hello</a>),
        text { 'hello' }
    ),
    (: unwrap a sequence of elements :)
    unit:assert-equals(
        xf:unwrap((<a><b/></a>,<c><d/></c>)),
        (<b/>,<d/>)
    ),
    (: some nodes can't be unwrapped so they are passed through :)
    unit:assert-equals(
        xf:unwrap((<a><b/></a>, text { 'hello' })),
        (<b/>, text { 'hello' })
    )
};

declare %unit:test function test:content() {
    (: replace the content of an element :)
    unit:assert-equals(
        xf:content(<a>foobar</a>, text { 'hello' }),
        <a>hello</a>
    ),
    (: replace the content of an empty element :)
    unit:assert-equals(
        xf:content(<a/>, text { 'hello' }),
        <a>hello</a>
    ),
    (: empty the content of an element :)
    unit:assert-equals(
        xf:content(<a>foobar</a>, ()),
        <a/>
    ),
    (: empty nodes are never changed :)
    unit:assert-equals(
        xf:content((), <foo/>),
        ()
    )    
};

declare %unit:test function test:replace() {
    (: replace the content of an element :)
    unit:assert-equals(
        xf:replace(<a>foobar</a>, text { 'hello' }),
        text { 'hello' }
    ),
    (: replace the content of an empty element :)
    unit:assert-equals(
        xf:replace(<a/>, text { 'hello' }),
        text { 'hello' }
    ),
    (: other nodes can also be replaced :)
    unit:assert-equals(
        xf:replace(text { 'foobar' }, text { 'hello' }),
        text { 'hello' }
    ),
    (: comments too :)
    unit:assert-equals(
        xf:replace(<!-- foobar -->, text { 'hello' }),
        text { 'hello' }
    ),
    (: empty the content of an element :)
    unit:assert-equals(
        xf:replace(<a>foobar</a>, ()),
        ()
    ),
    (: empty nodes are never replaced :)
    unit:assert-equals(
        xf:replace((), <foo/>),
        ()
    )
};

declare %unit:test function test:set-attr() {
    (: add a new atrribute :)
    unit:assert-equals(
        xf:set-attr(<a/>, map { 'x': 10 }),
        <a x="10"/>
    ),
    (: change an atrribute :)
    unit:assert-equals(
        xf:set-attr(<a x="0"/>, map { 'x': 10 }),
        <a x="10"/>
    ),   
    (: change an atrribute using another elements attributes :)
    unit:assert-equals(
        xf:set-attr(<a x="0"/>, <b x="10"/>),
        <a x="10"/>
    ),   
    (: change an atrribute on multiple elements :)
    unit:assert-equals(
        xf:set-attr((<a x="0"/>,<b y="0"/>), map { 'x': 10 }),
        (<a x="10"/>,<b y="0" x="10"/>)
    ),
    (: child elements are not modified :)    
    unit:assert-equals(
        xf:set-attr(<a><b/></a>, map { 'x': 10 }),
        <a x="10"><b/></a>
    ),
    (: nodes that are not elements are not modified :)    
    unit:assert-equals(
        xf:set-attr(text { 'foo' }, <b x="10"/>),
        text { 'foo' }
    ),
    (: empty nodes are not modified :)    
    unit:assert-equals(
        xf:set-attr((), <b x="10"/>),
        ()
    )
};

declare %unit:test function test:remove-attr() {
    (: remove atrribute :)
    unit:assert-equals(
        xf:remove-attr(<a x="10"/>, 'x'),
        <a/>
    ),
    (: remove multiple atrributes :)
    unit:assert-equals(
        xf:remove-attr(<a x="10" y="20"/>, ('x','y')),
        <a/>
    ),   
    (: remove multiple atrributes from multiple elements :)
    unit:assert-equals(
        xf:remove-attr((<a x="10" z="20"/>,text { 'foo' },<b y="10"/>), ('x','y')),
        (<a z="20"/>,text { 'foo' },<b/>)
    ),
    (: empty nodes are not modified :)
    unit:assert-equals(
        xf:remove-attr((), ('x','y')),
        ()
    ),   
    (: no attributes removed :)
    unit:assert-equals(
        xf:remove-attr((<a x="10"/>,<b y="20"/>), ()),
        (<a x="10"/>,<b y="20"/>)
    ),   
    (: use element with attributes to provide the attributes to remove :)
    unit:assert-equals(
        xf:remove-attr((<a x="10" z="20"/>,text { 'foo' },<b y="10"/>), <b x="" y=""/>),
        (<a z="20"/>,text { 'foo' },<b/>)
    ),   
    (: use map to provide the attributes to remove :)
    unit:assert-equals(
        xf:remove-attr((<a x="10" z="20"/>,text { 'foo' },<b y="10"/>), map { 'x': '', 'y': '' }),
        (<a z="20"/>,text { 'foo' },<b/>)
    )   
};

declare %unit:test function test:add-class() {
    (: add single class token :)
    unit:assert-equals(
        xf:add-class(<foo/>,('a')),
        <foo class="a"/>
    ),
    (: add class token that already exists :)
    unit:assert-equals(
        xf:add-class(<foo class="foo a"/>,('a')),
        <foo class="foo a"/>
    ),
    (: add class tokens, both already exist :)
    unit:assert-equals(
        xf:add-class(<foo class="a"/>,('a','b')),
        <foo class="a b"/>
    ),
    (: add class tokens, one of them already exists :)
    unit:assert-equals(
        xf:add-class(<foo class="a"/>,('a b')),
        <foo class="a b"/>
    ),
    (: empty nodes aren't touched :)
    unit:assert-equals(
        xf:add-class((),('a','b')),
        ()
    ),
    (: add class tokens to a sequence of nodes :)
    unit:assert-equals(
        xf:add-class((<foo/>,text { 'foo' },<bar/>),('a','b')),
        (<foo class="a b"/>,text { 'foo' },<bar class="a b"/>)
    )
};

declare %unit:test function test:remove-class() {
    unit:assert-equals(
        xf:remove-class(<foo class="a"/>, 'a'),
        <foo/>
    ),
    unit:assert-equals(
        xf:remove-class(<foo class="b a"/>, 'a'),
        <foo class="b"/>
    ),
    unit:assert-equals(
        xf:remove-class(<foo class="b a"/>, 'x'),
        <foo class="b a"/>
    ),
    unit:assert-equals(
        xf:remove-class(<foo class="b a"/>, ()),
        <foo class="b a"/>
    ),
    unit:assert-equals(
        xf:remove-class((<foo class="b a"/>,<bar class="b a"/>), 'a'),
        (<foo class="b"/>,<bar class="b"/>)
    ),
    unit:assert-equals(
        xf:remove-class((<foo class="b a"/>,text { 'foo' }), 'a'),
        (<foo class="b"/>,text { 'foo' })
    ),
    unit:assert-equals(
        xf:remove-class((), 'a'),
        ()
    )
};

declare %unit:test function test:text() {
    unit:assert-equals(
        xf:text(text { 'foo' }),
        text { 'foo' }
    ),
    unit:assert-equals(
        xf:text((text { 'foo' }, text { 'bar' })),
        text { 'foobar' }
    ),
    unit:assert-equals(
        xf:text(<a>foo</a>),
        text { 'foo' }
    ),
    unit:assert-equals(
        xf:text((<a>foo</a>,<b>bar</b>)),
        text { 'foobar' }
    ),
    unit:assert-equals(
        xf:text(<a>foo <b x="10">bar</b></a>),
        text { 'foo bar' }
    ),
    unit:assert-equals(
        xf:text(()),
        ())
};

declare %unit:test function test:append() {
    unit:assert-equals(
        xf:append(<a/>,<b/>),
        <a><b/></a>
    ),
    unit:assert-equals(
        xf:append(<a><c/></a>,<b/>),
        <a><c/><b/></a>
    ),
    unit:assert-equals(
        xf:append(<a><c/></a>,text { 'foo' }),
        <a><c/>foo</a>
    ),
    unit:assert-equals(
        xf:append(<a/>,()),
        <a/>
    ),
    unit:assert-equals(
        xf:append(<a><c/></a>,()),
        <a><c/></a>
    ),
    unit:assert-equals(
        xf:append((<a/>,<b/>),(<c/>,<d/>)),
        (<a><c/><d/></a>,<b><c/><d/></b>)
    ),
    unit:assert-equals(
        xf:append((<a/>,text { 'foo' }),(<c/>,<d/>)),
        (<a><c/><d/></a>,text { 'foo' })
    ),
    unit:assert-equals(
        xf:append((),()),
        ()
    )
};

declare %unit:test function test:prepend() {
    unit:assert-equals(
        xf:prepend(<a/>,<b/>),
        <a><b/></a>
    ),
    unit:assert-equals(
        xf:prepend(<a><c/></a>,<b/>),
        <a><b/><c/></a>
    ),
    unit:assert-equals(
        xf:prepend(<a><c/></a>,text { 'foo' }),
        <a>foo<c/></a>
    ),
    unit:assert-equals(
        xf:prepend(<a/>,()),
        <a/>
    ),
    unit:assert-equals(
        xf:prepend(<a><c/></a>,()),
        <a><c/></a>
    ),
    unit:assert-equals(
        xf:prepend((<a/>,<b/>),(<c/>,<d/>)),
        (<a><c/><d/></a>,<b><c/><d/></b>)
    ),
    unit:assert-equals(
        xf:prepend((<a/>,text { 'foo' }),(<c/>,<d/>)),
        (<a><c/><d/></a>,text { 'foo' })
    ),
    unit:assert-equals(
        xf:prepend((),()),
        ()
    )
};

declare %unit:test function test:before() {
    unit:assert-equals(
        xf:before(<a/>,<b/>),
        (<b/>,<a/>)
    ),
    unit:assert-equals(
        xf:before(<a><c/></a>,<b/>),
        (<b/>,<a><c/></a>)
    ),
    unit:assert-equals(
        xf:before(<a/>,text { 'foo' }),
        (text { 'foo' },<a/>)
    ),
    unit:assert-equals(
        xf:before(<a/>,()),
        <a/>
    ),
    unit:assert-equals(
        xf:before((),()),
        ()
    )
};

declare %unit:test function test:after() {
    unit:assert-equals(
        xf:after(<a/>,<b/>),
        (<a/>,<b/>)
    ),
    unit:assert-equals(
        xf:after(<a><c/></a>,<b/>),
        (<a><c/></a>,<b/>)
    ),
    unit:assert-equals(
        xf:after(<a/>,text { 'foo' }),
        (<a/>, text { 'foo' })
    ),
    unit:assert-equals(
        xf:after(<a/>,()),
        <a/>
    ),
    unit:assert-equals(
        xf:after((),()),
        ()
    )
};

declare variable $test:stylesheet :=
    <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
        version="1.0">
        <xsl:template match="/">
            <a>
                <xsl:apply-templates/>
            </a>
        </xsl:template>
        <xsl:template match="foo">
            <bar/>
        </xsl:template>
    </xsl:stylesheet>;

declare %unit:test function test:xslt() {
    unit:assert-equals(
        xf:xslt(<foo/>,$test:stylesheet, map {}),
        <a><bar/></a>
    ),
    unit:assert-equals(
        xf:xslt((<foo/>,<foo/>),$test:stylesheet, map {}),
        (<a><bar/></a>, <a><bar/></a>)
    ),
    unit:assert-equals(
        xf:xslt((<foo/>,<bar/>,<foo/>),$test:stylesheet, map {}),
        (<a><bar/></a>, <a/>, <a><bar/></a>)
    ),
    unit:assert-equals(
        xf:xslt((<foo/>,text { 'foo' },<foo/>),$test:stylesheet, map {}),
        (<a><bar/></a>, text { 'foo' }, <a><bar/></a>)
    )
};

declare %unit:test function test:rename() {
    (: simple rename :)
    unit:assert-equals(
        xf:rename((<p/>,<p/>,<a/>,<p/>), map { 'p': 'x' }),
        (<x/>,<x/>,<a/>,<x/>)
    ),
    (: simple rename using string argument (all elements will be renamed) :)
    unit:assert-equals(
        xf:rename((<p/>,<p/>,<a/>,<p/>), 'x'),
        (<x/>,<x/>,<x/>,<x/>)
    ),
    (: simple rename using function :)
    unit:assert-equals(
        xf:rename((<p/>,<!-- hi -->,<a/>,text { 'hi' }), function($node) { 'x' }),
        (<x/>,<!-- hi -->,<x/>,text { 'hi' })
    ),
    (: pass non-element nodes through unmodified :)
    unit:assert-equals(
        xf:rename((<p/>,<!-- hi -->,<a/>,text { 'hi' }), map { 'p': 'x' }),
        (<x/>,<!-- hi -->,<a/>,text { 'hi' })
    ),
    (: do not replace child nodes :)
    unit:assert-equals(
        xf:rename((<p><p/></p>,<a><p/></a>), map { 'p': 'x' }),
        (<x><p/></x>,<a><p/></a>)
    ),
    (: replace namespaced names and multiple mappings :)
    unit:assert-equals(
        xf:rename((<test:p/>,<xf:p/>), map { 'test:p': 'x', 'xf:p': 'y' }),
        (<x/>,<y/>)
    )
};