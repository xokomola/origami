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

declare %unit:test function test:content-if() {
    (: replace the content of an element :)
    unit:assert-equals(
        xf:content-if(<a>foobar</a>, text { 'hello' }),
        <a>hello</a>
    ),
    (: replace the content of an empty element :)
    unit:assert-equals(
        xf:content-if(<a/>, text { 'hello' }),
        <a>hello</a>
    ),
    (: when there is no content, don't replace content :)
    unit:assert-equals(
        xf:content-if(<a>foobar</a>, ()),
        <a>foobar</a>
    ),
    (: empty nodes are never changed :)
    unit:assert-equals(
        xf:content-if((), <foo/>),
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

declare %unit:test function test:replace-if() {
    (: replace the content of an element :)
    unit:assert-equals(
        xf:replace-if(<a>foobar</a>, text { 'hello' }),
        text { 'hello' }
    ),
    (: replace the content of an empty element :)
    unit:assert-equals(
        xf:replace-if(<a/>, text { 'hello' }),
        text { 'hello' }
    ),
    (: comments too :)
    unit:assert-equals(
        xf:replace-if(<!-- foobar -->, text { 'hello' }),
        text { 'hello' }
    ),
    (: when there is no content, don't replace content :)
    unit:assert-equals(
        xf:replace-if(<a>foobar</a>, ()),
        <a>foobar</a>
    ),
    (: empty nodes are never replaced :)
    unit:assert-equals(
        xf:replace-if((), <foo/>),
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
    unit:assert-equals(1,1)
};

declare %unit:test %unit:ignore('TODO') function test:text() {
    unit:assert-equals(1,1)
};

declare %unit:test %unit:ignore('TODO') function test:append() {
    unit:assert-equals(1,1)
};

declare %unit:test %unit:ignore('TODO') function test:prepend() {
    unit:assert-equals(1,1)
};

declare %unit:test %unit:ignore('TODO') function test:before() {
    unit:assert-equals(1,1)
};

declare %unit:test %unit:ignore('TODO') function test:after() {
    unit:assert-equals(1,1)
};

declare %unit:test %unit:ignore('TODO') function test:xslt() {
    unit:assert-equals(1,1)
};


