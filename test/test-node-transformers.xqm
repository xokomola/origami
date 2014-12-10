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
